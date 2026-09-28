import json
import re
from pathlib import Path


def md_to_ipynb(md_file, ipynb_file=None):
    md_file = Path(md_file)

    if ipynb_file is None:
        ipynb_file = md_file.with_suffix(".ipynb")
    else:
        ipynb_file = Path(ipynb_file)

    text = md_file.read_text(encoding="utf-8")

    cells = []
    lines = text.splitlines()
    markdown_buffer = []
    code_buffer = []

    inside_code = False

    # def add_markdown(lines):
    #     content = "\n".join(lines).strip()

    #     if content:
    #         cells.append({
    #             "cell_type": "markdown",
    #             "metadata": {},
    #             "source": [
    #                 line + "\n"
    #                 for line in content.splitlines()
    #             ]
    #         })

    def add_markdown(lines):
        for line in lines:
            # Strip trailing newlines or spaces if desired, but keep the text
            clean_line = line.rstrip("\n")
            
            # Skip completely empty lines if you don't want blank cells
            if clean_line.strip():
                cells.append({
                    "cell_type": "markdown",
                    "metadata": {},
                    # Jupyter expects each line in the source list to end with "\n"
                    "source": [clean_line + "\n"] 
                })
    def add_code(lines):
        content = "\n".join(lines).strip()

        if content:
            cells.append({
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": [
                    line + "\n"
                    for line in content.splitlines()
                ]
            })

    for line in lines:

        # Code block
        if line.startswith("```"):

            if inside_code:
                add_code(code_buffer)

                code_buffer = []
                inside_code = False

            else:
                if markdown_buffer:
                    add_markdown(markdown_buffer)
                    markdown_buffer = []

                inside_code = True

            continue

        # Inside code
        if inside_code:
            code_buffer.append(line)
            continue

        # Heading
        if re.match(r"^#{1,6}\s+", line):

            if markdown_buffer:
                add_markdown(markdown_buffer)
                markdown_buffer = []

            # Remove existing # symbols
            heading_text = re.sub(
                r"^#{1,6}\s+",
                "",
                line
            ).strip()

            # Always start headings with ###
            heading = f"##### {heading_text}"

            cells.append({
                "cell_type": "markdown",
                "metadata": {},
                "source": [heading + "\n"]
            })

            continue

        # Normal Markdown
        markdown_buffer.append(line)

    # Remaining code
    if code_buffer:
        add_code(code_buffer)

    # Remaining Markdown
    if markdown_buffer:
        add_markdown(markdown_buffer)

    notebook = {
        "cells": cells,
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3"
            },
            "language_info": {
                "name": "python"
            }
        },
        "nbformat": 4,
        "nbformat_minor": 5
    }

    ipynb_file.write_text(
        json.dumps(
            notebook,
            indent=2,
            ensure_ascii=False
        ),
        encoding="utf-8"
    )

    print(f"Created: {ipynb_file}")


# Example
md_to_ipynb("Test\PLP\DGTP\Ques.md")