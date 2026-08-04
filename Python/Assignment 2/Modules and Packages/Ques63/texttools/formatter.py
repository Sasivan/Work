def title_case(txt):
    return txt.title()
def slug_from_string(txt):
    return "-".join(txt.split())
def truncate(txt,n):
    if len(txt) > n: return txt[:n]+'...'
    return txt
