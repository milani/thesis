# Makefile for LaTeX files

BUILDDIR = build/
LATEX	= xelatex -output-directory=$(BUILDDIR) -interaction=batchmode -no-shell-escape
BIBTEX	= bibtex
MAKEINDEX = makeindex

RERUN = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
RERUNBIB = "No file.*\.bbl|Citation.*undefined"
MAKEIDX = "^[^%]*\\makeindex"
MPRINT = "^[^%]*print"
USETHUMBS = "^[^%]*thumbpdf"

SRC	:= $(shell egrep -l '^[^%]*\\begin\{document\}' *.tex)
BIBFILE := $(shell perl -ne '($$_)=/^[^%]*\\bibliography\{(.*?)\}/;@_=split /,/;foreach $$b (@_) {print "$$b.bib "}' $(SRC))

PDFPICS := $(shell perl -ne '@foo=/^[^%]*\\(includegraphics)(\[.*?\])?\{(.*?)\}/g;if (defined($$foo[2])) { if ($$foo[2] =~ /.eps$$/) { print "$$foo[2] "; } else { print "$$foo[2].eps "; }}' *.tex)
DEP	= *.tex

TRG	= $(SRC:%.tex=%.pdf)

COPY = if test -r $(<:%.tex=%.toc); then cp $(<:%.tex=%.toc) $(<:%.tex=%.toc.bak); fi 
RM = rm -f
OUTDATED = echo "EPS-file is out-of-date!" && false

OPEN = evince

all 	: $(TRG)

define run-latex
	  echo "$(LATEX) $<"
	  $(COPY);$(LATEX) $<||(egrep -A 3 -i "(Reference|Citation|!).*(U|u)ndefined" $(<:%.tex=$(BUILDDIR)%.log);exit 1)
	  egrep -q $(MAKEIDX) $< && ($(MAKEINDEX) $(<:%.tex=%);$(COPY);$(LATEX) $<) ; true
	  egrep -c $(RERUNBIB) $(<:%.tex=$(BUILDDIR)%.log) && ($(BIBTEX) $(<:%.tex=$(BUILDDIR)%);$(COPY);$(LATEX) $<) ; true
	  egrep -q $(RERUN) $(<:%.tex=$(BUILDDIR)%.log) && ($(COPY);$(LATEX) $<) ; true
	  egrep -q $(RERUN) $(<:%.tex=$(BUILDDIR)%.log) && ($(COPY);$(LATEX) $<) ; true
	  if cmp -s $(<:%.tex=$(BUILDDIR)%.toc) $(<:%.tex=$(BUILDDIR)%.toc.bak); then true ;else $(LATEX) $< ; fi
	  $(RM) $(<:%.tex=$(BUILDDIR)%.toc.bak)
	  cp $(<:%.tex=$(BUILDDIR)%.pdf) ./
	  # Display relevant warnings
	  egrep -i "(Reference|Citation).*undefined" $(<:%.tex=$(BUILDDIR)%.log) ; true
endef

$(TRG)	: %.pdf : %.tex $(DEP) $(PDFPICS) $(BIBFILE)
	  @$(run-latex)

clean	:
	  echo $(BIBFILE)
	  -rm -f $(TRG) $(PSF) $(PDF) $(TRG:%.pdf=%.aux) $(TRG:%.pdf=%.bbl) $(TRG:%.pdf=%.blg) $(TRG:%.pdf=%.log) $(TRG:%.pdf=%.out)

show	:
	  @$(OPEN) $(TRG)

.PHONY	: all clean ps pdf

######################################################################
# Define rules for PDF source files.
%.pdf: %.eps
	epstopdf $< > $(<:%.eps=%.pdf)
