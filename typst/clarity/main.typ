// ── Imports ────────────────────────────────────────────────────────────────
#import "theme.typ": note, tip, warning, danger, setup
#import "metadata.typ": book-title, book-subtitle, book-author
#show: setup

#set document(
  title: book-title,
  author: book-author
)

// ── Typography ─────────────────────────────────────────────────────────────
#set text(
  font: "New Computer Modern", 
  size: 11pt, 
  lang: "en"
  )
#set par(
  justify: false, 
  leading: 0.75em
  )
#set heading(numbering: "1.1")

// ── Page layout ────────────────────────────────────────────────────────────
#set page(
  paper: "a4",
  margin: (x: 3.5cm, top: 3cm, bottom: 3.5cm),
  numbering: "1",
  footer: context align(center,
    text(size: 9pt, fill: luma(160), counter(page).display("1"))
  ),
)

// ── Frontmatter ────────────────────────────────────────────────────────────
#include "frontmatter.typ"

// ── Chapters ───────────────────────────────────────────────────────────────
// Uncomment / add lines below as you write new chapters:
#include "chapters/ch01-principles.typ"
#include "chapters/ch02-python-features.typ"
#include "chapters/ch03-collaborative-dev.typ"
#include "chapters/ch04-production-practices.typ"

