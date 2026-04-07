// theme.typ — Callout boxes and document styling

#let _callout(color, icon, title, body) = block(
  width: 100%,
  stroke: (left: 4pt + color),
  fill: color.lighten(90%),
  inset: (left: 1em, right: 1em, top: 0.75em, bottom: 0.75em),
  radius: (right: 4pt),
)[
  #text(weight: "bold", fill: color)[#icon  #title]
  #parbreak()
  #body
]

#let note(body, title: "Note")       = _callout(rgb("#1976D2"), "ⓘ", title, body)
#let tip(body, title: "Tip")         = _callout(rgb("#388E3C"), "✦", title, body)
#let warning(body, title: "Warning") = _callout(rgb("#F57C00"), "▲", title, body)
#let danger(body, title: "Danger")   = _callout(rgb("#C62828"), "✖", title, body)

// ── Chapter intro page ─────────────────────────────────────────────────────
// Usage: place immediately after a level-1 heading.
// Renders the description, a mini TOC of the chapter's sections, then breaks.
#let chapter-intro(body) = context {
  let loc = here()

  // Is location a before location b in reading order?
  let comes-before(a, b) = {
    let ap = a.position()
    let bp = b.position()
    ap.page < bp.page or (ap.page == bp.page and ap.y < bp.y)
  }

  // Find the next chapter heading so we can bound the section query
  let next-chapter = query(heading.where(level: 1))
    .find(h => comes-before(loc, h.location()))

  // Collect level-2 headings belonging to this chapter
  let sections = query(heading.where(level: 2)).filter(h => {
    let hloc = h.location()
    comes-before(loc, hloc) and (
      next-chapter == none or comes-before(hloc, next-chapter.location())
    )
  })

  // ── Intro text ─────────────────────────────────────────────────────────
  v(3em)
  body

  // ── Mini TOC ───────────────────────────────────────────────────────────
  if sections.len() > 0 {
    v(2.5em)
    text(size: 9pt, weight: "bold", fill: luma(120), tracking: 0.08em)[IN THIS CHAPTER]
    v(0.6em)
    line(length: 100%, stroke: 0.5pt + luma(220))
    v(0.4em)

    for section in sections {
      let num = numbering("1.1", ..counter(heading).at(section.location()))
      block(above: 0.35em, below: 0.35em,
        grid(
          columns: (2.5em, 1fr, 2em),
          align: (right, left, right),
          column-gutter: 0.6em,
          text(size: 10pt, fill: luma(140), num),
          link(section.location())[#text(size: 10pt)[#section.body]],
          text(size: 10pt, fill: luma(140), str(section.location().page())),
        )
      )
    }
  }

  pagebreak()
}

// ── Document setup — activated via `#show: setup` in main.typ ──────────────
#let setup(doc) = {
  // Fenced/block code  (```python ... ```)
  show raw.where(block: true): it => block(
    width: 100%,
    fill: luma(248),
    stroke: (left: 3pt + rgb("#4a9eff")),
    inset: (x: 1.2em, y: 0.9em),
    radius: (right: 4pt),
  )[
    #if it.lang != none {
      place(top + right, dx: -0.4em, dy: 0.4em,
        text(size: 8pt, fill: luma(160), weight: "bold", it.lang)
      )
    }
    #it
  ]

  // Inline code  (`like this`)
  show raw.where(block: false): it => box(
    fill: luma(235),
    inset: (x: 3pt, y: 1pt),
    radius: 2pt,
    it,
  )

  // Chapter headings (level 1)
  show heading.where(level: 1): it => {
    // Unnumbered headings (e.g. the TOC title) get plain rendering
    if it.numbering == none {
      return block(above: 2em, below: 1em, text(size: 16pt, weight: "bold", it.body))
    }

    pagebreak(weak: true)
    v(3em)

    // Right-aligned ornament: rotated "CHAPTER" label + big number box
    align(right,
      stack(dir: ltr, spacing: 0pt,
        block(width: 1.5cm, height: 3cm,
          align(center + horizon,
            rotate(-90deg,
              text(size: 8pt, tracking: 0.35em, weight: "bold", fill: luma(150), "CHAPTER")
            )
          )
        ),
        block(fill: luma(80), width: 3cm, height: 3cm,
          align(center + horizon,
            context text(size: 52pt, weight: "bold", fill: white,
              str(counter(heading).at(it.location()).first())
            )
          )
        )
      )
    )

    v(1.5em)
    line(length: 100%, stroke: 0.5pt + luma(200))
    v(1em)
    align(center, text(size: 14pt, weight: "bold", smallcaps(it.body)))
    v(3em)
  }

  doc
}
