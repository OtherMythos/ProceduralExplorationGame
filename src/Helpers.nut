::wrapToString <- function(obj, name, desc){
    return format("(%s '%s: %s')", typeof obj, name, desc);
}