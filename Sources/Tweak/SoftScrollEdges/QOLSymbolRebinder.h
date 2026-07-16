#import <Foundation/Foundation.h>

typedef struct {
    const char *name;
    void *replacement;
} QOLSymbolRebinding;

FOUNDATION_EXPORT int QOLRebindSymbols(QOLSymbolRebinding rebindings[], size_t count);
