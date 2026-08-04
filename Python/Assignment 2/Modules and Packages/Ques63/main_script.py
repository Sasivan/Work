# main_script.py
import texttools

sample_text = "Hello world! Python packages are great."

print("--- texttools Package Demonstration ---")
print(f"Word Count: {texttools.word_count(sample_text)}")
print(f"Avg Word Length: {texttools.avg_word_length(sample_text):.2f}")
print(f"Char Freq ('o'): {texttools.char_frequency(sample_text).get('o', 0)}")

title = "A Guide to Python Packaging!"
print(f"\nTitle Case: {texttools.title_case(title)}")
print(f"Slug: {texttools.slug_from_string(title)}")
print(f"Truncated: {texttools.truncate(title, 15)}")