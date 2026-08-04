# texttools/__init__.py

from .analyzer import word_count, char_frequency, avg_word_length
from .formatter import title_case, slug_from_string, truncate

# Expose exactly these 6 functions at the package level
__all__ = [
    'word_count', 'char_frequency', 'avg_word_length',
    'title_case', 'slug_from_string', 'truncate'
]