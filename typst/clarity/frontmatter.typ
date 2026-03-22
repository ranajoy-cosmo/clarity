// frontmatter.typ — Cover, preface, and table of contents
#import "metadata.typ": book-title, book-subtitle, book-author

// ── Cover page ─────────────────────────────────────────────────────────────
#page(numbering: none, footer: none)[
  #align(center + horizon)[
    #text(size: 42pt, weight: "bold")[#book-title]
    #v(0.5em)
    #text(size: 18pt, fill: luma(120))[#book-subtitle]
    #v(5em)
    #line(length: 35%, stroke: 0.5pt + luma(200))
    #v(1.5em)
    #text(size: 13pt)[#book-author]
    #v(0.5em)
    #text(size: 11pt, fill: luma(160))[#datetime.today().display("[year]")]
  ]
]

// ── Why this book ──────────────────────────────────────────────────────────
#page(numbering: none, footer: none)[
  #align(center)[
    #v(4em)
    #text(size: 16pt, weight: "bold")[Why this book?]
    #v(1.5em)
    #line(length: 25%, stroke: 0.5pt + luma(200))
    #v(1.5em)
  ]

  #set par(justify: true, leading: 1em)
  #text(size: 11pt)[
    Over years of building software, I found myself re-learning the same
    lessons — rediscovering patterns, retracing debugging paths, rewriting
    explanations to teammates. This book is the record I wish I had kept from
    the start.

    It is not a reference manual. It is a distillation of what actually
    mattered: the ideas that changed how I think, the mistakes that cost me
    the most, and the practices that held up under pressure. Written plainly,
    for my own clarity first, and for anyone who finds it useful second.
  ]
]

// ── Table of contents ──────────────────────────────────────────────────────
#page(numbering: none, footer: none)[
  #outline(title: "Contents", indent: auto, depth: 3)
]

// Reset page counter so chapter 1 starts at page 1
#counter(page).update(1)
