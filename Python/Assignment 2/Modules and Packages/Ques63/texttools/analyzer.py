def word_count(txt):
    return len(txt.split())
def char_frequency(txt):
    d = {}
    for i in txt:
        if i not in d.keys():
            d[i] = 1
        else: d[i] += 1
    return d
def avg_word_length(txt):
    avg = sum(len(w) for w in txt.split())
    return avg/len(txt.split())
