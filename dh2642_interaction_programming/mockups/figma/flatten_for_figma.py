#!/usr/bin/env python3
"""
Flatten CSS classes in the Catch Up! wireframe SVGs into presentation attributes.

Why this exists
---------------
The authored SVGs keep their styling in a single <style> block so the wireframes
stay editable by hand. Figma's SVG importer does not apply CSS class rules from a
<style> block, so importing the authored file directly produces unstyled black
shapes. This script resolves every class into plain presentation attributes and
drops the <style> block, which is what Figma (and Sketch, Illustrator, Word,
LibreOffice) can read reliably.

Precedence implemented, lowest to highest:
    1. a presentation attribute already written on the element
    2. class rules, in the order the classes are listed on the element
    3. an inline style="..." attribute on the element

This is the CSS cascade, not an arbitrary choice. SVG presentation attributes
behave as author-level declarations with specificity 0, inserted at the start of
the author stylesheet, so *any* class rule overrides them. Getting this backwards
produces a file that no longer matches the approved render: for example
`<text class="cap" font-size="22">` renders at the class's 14px, not at 22px.
Verified against the authored renders with a pixel diff (0 differing pixels).

Usage
-----
    python3 flatten_for_figma.py IN.svg OUT.svg
"""

import re
import sys
import xml.etree.ElementTree as ET

SVG_NS = "http://www.w3.org/2000/svg"

# Properties we expect in these wireframes. Everything here is valid both as a
# CSS property and as an SVG presentation attribute.
ALLOWED = {
    "fill", "fill-opacity", "stroke", "stroke-width", "stroke-dasharray",
    "stroke-linecap", "stroke-linejoin", "opacity", "font-size", "font-weight",
    "font-family", "font-style", "text-anchor", "letter-spacing", "rx", "ry",
    "dominant-baseline",
}


def parse_style_block(css):
    """Return {class_name: {prop: value}} from a CSS string."""
    rules = {}
    for selector, body in re.findall(r"\.([A-Za-z0-9_-]+)\s*\{([^}]*)\}", css):
        decls = {}
        for decl in body.split(";"):
            if ":" not in decl:
                continue
            prop, _, value = decl.partition(":")
            prop = prop.strip()
            value = value.strip()
            if prop in ALLOWED and value:
                decls[prop] = value
        if decls:
            rules.setdefault(selector, {}).update(decls)
    return rules


def parse_inline_style(style):
    decls = {}
    for decl in style.split(";"):
        if ":" not in decl:
            continue
        prop, _, value = decl.partition(":")
        prop = prop.strip()
        value = value.strip()
        if prop in ALLOWED and value:
            decls[prop] = value
    return decls


def flatten(in_path, out_path):
    ET.register_namespace("", SVG_NS)
    tree = ET.parse(in_path)
    root = tree.getroot()

    # 1. Collect the CSS, then remove the <style> elements (and the <defs> if empty).
    rules = {}
    for defs in root.iter():
        for style_el in list(defs):
            if style_el.tag == f"{{{SVG_NS}}}style":
                rules.update(parse_style_block(style_el.text or ""))
                defs.remove(style_el)

    # 2. Resolve classes on every element.
    renamed = 0
    styled = 0
    for el in root.iter():
        classes = el.get("class")
        inline = el.get("style")
        if not classes and not inline:
            continue

        # Lowest priority first: whatever presentation attributes already exist.
        resolved = {p: v for p, v in el.attrib.items() if p in ALLOWED}
        # Then the class rules, in the order they are listed on the element.
        if classes:
            for name in classes.split():
                resolved.update(rules.get(name, {}))
        # Then the inline style attribute, which beats both.
        if inline:
            resolved.update(parse_inline_style(inline))

        for prop, value in resolved.items():
            el.set(prop, value)

        if classes:
            # Keep the class name as a Figma-visible layer name hint when the
            # element has no better name, then drop the attribute.
            if el.get("data-name") is None and el.tag == f"{{{SVG_NS}}}g":
                el.set("data-name", classes)
                renamed += 1
            del el.attrib["class"]
        if inline:
            del el.attrib["style"]
        styled += 1

    # 3. Drop an empty <defs>.
    for parent in root.iter():
        for child in list(parent):
            if child.tag == f"{{{SVG_NS}}}defs" and len(child) == 0 and not (child.text or "").strip():
                parent.remove(child)

    tree.write(out_path, encoding="utf-8", xml_declaration=True)
    return len(rules), styled, renamed


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    n_rules, n_styled, n_named = flatten(sys.argv[1], sys.argv[2])
    print(f"{sys.argv[1]} -> {sys.argv[2]}")
    print(f"  {n_rules} class rules resolved onto {n_styled} elements")
