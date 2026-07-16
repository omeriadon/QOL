#import "QOLSymbolRebinder.h"

#import <mach-o/dyld.h>
#import <mach-o/nlist.h>
#import <mach/mach.h>
#import <ptrauth.h>
#import <string.h>

static QOLSymbolRebinding *QOLRebindings;
static size_t QOLRebindingCount;

static void QOLRebindSection(intptr_t slide,
                             const struct section_64 *section,
                             const struct symtab_command *symbolTableCommand,
                             const struct dysymtab_command *dynamicSymbolTableCommand,
                             uintptr_t linkEditBase) {
    uint32_t *indirectSymbolTable = (uint32_t *)(linkEditBase + dynamicSymbolTableCommand->indirectsymoff);
    struct nlist_64 *symbolTable = (struct nlist_64 *)(linkEditBase + symbolTableCommand->symoff);
    char *stringTable = (char *)(linkEditBase + symbolTableCommand->stroff);
    void **bindings = (void **)(slide + section->addr);
    uint32_t *indices = indirectSymbolTable + section->reserved1;
    size_t bindingCount = section->size / sizeof(void *);

    for (size_t bindingIndex = 0; bindingIndex < bindingCount; bindingIndex++) {
        uint32_t symbolIndex = indices[bindingIndex];
        if (symbolIndex == INDIRECT_SYMBOL_ABS || symbolIndex == INDIRECT_SYMBOL_LOCAL ||
            symbolIndex == (INDIRECT_SYMBOL_LOCAL | INDIRECT_SYMBOL_ABS)) {
            continue;
        }

        uint32_t stringOffset = symbolTable[symbolIndex].n_un.n_strx;
        if (stringOffset == 0) continue;
        const char *symbolName = stringTable + stringOffset;
        if (symbolName[0] == '_') symbolName += 1;

        for (size_t rebindingIndex = 0; rebindingIndex < QOLRebindingCount; rebindingIndex++) {
            QOLSymbolRebinding *rebinding = &QOLRebindings[rebindingIndex];
            if (strcmp(symbolName, rebinding->name) != 0) continue;
            kern_return_t protectionResult = vm_protect(mach_task_self(),
                                                         (vm_address_t)bindings,
                                                         (vm_size_t)section->size,
                                                         false,
                                                         VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            if (protectionResult == KERN_SUCCESS) {
                void *replacement = rebinding->replacement;
#if __has_feature(ptrauth_calls)
                if (strcmp(section->sectname, "__auth_got") == 0) {
                    replacement = ptrauth_strip(replacement, ptrauth_key_process_independent_code);
                    replacement = ptrauth_sign_unauthenticated(
                        replacement,
                        ptrauth_key_process_independent_code,
                        (ptrauth_extra_data_t)&bindings[bindingIndex]
                    );
                }
#endif
                bindings[bindingIndex] = replacement;
            }
            break;
        }
    }
}

static void QOLRebindImage(const struct mach_header *rawHeader, intptr_t slide) {
    if (rawHeader->magic != MH_MAGIC_64) return;
    const struct mach_header_64 *header = (const struct mach_header_64 *)rawHeader;
    const struct load_command *command = (const struct load_command *)(header + 1);
    const struct symtab_command *symbolTableCommand = NULL;
    const struct dysymtab_command *dynamicSymbolTableCommand = NULL;
    const struct segment_command_64 *linkEditSegment = NULL;

    for (uint32_t index = 0; index < header->ncmds; index++) {
        if (command->cmd == LC_SYMTAB) symbolTableCommand = (const struct symtab_command *)command;
        if (command->cmd == LC_DYSYMTAB) dynamicSymbolTableCommand = (const struct dysymtab_command *)command;
        if (command->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *segment = (const struct segment_command_64 *)command;
            if (strcmp(segment->segname, SEG_LINKEDIT) == 0) linkEditSegment = segment;
        }
        command = (const struct load_command *)((const uint8_t *)command + command->cmdsize);
    }
    if (!symbolTableCommand || !dynamicSymbolTableCommand || !linkEditSegment) return;

    uintptr_t linkEditBase = slide + linkEditSegment->vmaddr - linkEditSegment->fileoff;
    command = (const struct load_command *)(header + 1);
    for (uint32_t index = 0; index < header->ncmds; index++) {
        if (command->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *segment = (const struct segment_command_64 *)command;
            if (strcmp(segment->segname, SEG_DATA) != 0 &&
                strcmp(segment->segname, "__DATA_CONST") != 0) {
                command = (const struct load_command *)((const uint8_t *)command + command->cmdsize);
                continue;
            }
            const struct section_64 *section = (const struct section_64 *)(segment + 1);
            for (uint32_t sectionIndex = 0; sectionIndex < segment->nsects; sectionIndex++) {
                uint32_t type = section[sectionIndex].flags & SECTION_TYPE;
                if (type == S_LAZY_SYMBOL_POINTERS || type == S_NON_LAZY_SYMBOL_POINTERS) {
                    QOLRebindSection(slide, &section[sectionIndex], symbolTableCommand,
                                     dynamicSymbolTableCommand, linkEditBase);
                }
            }
        }
        command = (const struct load_command *)((const uint8_t *)command + command->cmdsize);
    }
}

int QOLRebindSymbols(QOLSymbolRebinding rebindings[], size_t count) {
    if (!rebindings || count == 0 || QOLRebindings) return -1;
    QOLRebindings = calloc(count, sizeof(QOLSymbolRebinding));
    if (!QOLRebindings) return -1;
    memcpy(QOLRebindings, rebindings, count * sizeof(QOLSymbolRebinding));
    QOLRebindingCount = count;

    _dyld_register_func_for_add_image(QOLRebindImage);
    return 0;
}
