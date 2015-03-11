# Makefile for LaTeX files
OS = $(shell uname -s)

BUILDDIR = build/
LATEX	= xelatex -output-directory=$(BUILDDIR) -interaction=batchmode -no-shell-escape
BIBTEX	= bibtex
MAKEINDEX = makeindex
# MAKEGLOSSARY = xindy -L persian-variant1 -C utf8 -I xindy -M $(BUILDDIR)/%.xdy -t $(BUILDDIR)/%.glg -o $(BUILDDIR)/%.gls $(BUILDDIR)/%.glo | xindy -L persian-variant1 -C utf8 -I xindy -M $(BUILDDIR)/%.xdy -t $(BUILDDIR)/%.blg -o $(BUILDDIR)/%.bls $(BUILDDIR)/%.blo | xindy -L english -C utf8 -I xindy -M $(BUILDDIR)/%.xdy -t $(BUILDDIR)/%.alg -o $(BUILDDIR)/%.acr $(BUILDDIR)/%.acn
MAKEGLOSSARY = makeglossaries -d $(BUILDDIR) 

RERUN = "(There were undefined references|Rerun to get (cross-references|the bars) right)"
RERUNBIB = "No file.*\.bbl|Citation.*undefined"
MAKEIDX = "^[^%]*\\makeindex"
# GLOSSARY = "^[^%]*\\makeglossaries"
MPRINT = "^[^%]*print"
USETHUMBS = "^[^%]*thumbpdf"

SRC	 := $(shell egrep -l '^[^%]*\\begin\{document\}' *.tex)
BIBFILE  := $(shell perl -ne '($$_)=/^[^%]*\\bibliography\{(.*?)\}/;@_=split /,/;foreach $$b (@_) {print "$$b.bib "}' $(SRC))
GLOSSARY := $(shell egrep -l '^[^%]*\\makeglossaries' *.tex)


PDFPICS := $(shell perl -ne '@foo=/^[^%]*\\(includegraphics)(\[.*?\])?\{(.*?)\}/g;if (defined($$foo[2])) { if ($$foo[2] =~ /.eps$$/) { print "$$foo[2] "; } elsif ($$foo[2] =~ /.png|.pdf$$/) {"";} else { print "$$foo[2].eps "; }}' *.tex)
DEP	= *.tex

TRG	= $(SRC:%.tex=%.pdf)

COPY = if test -r $(<:%.tex=%.toc); then cp $(<:%.tex=%.toc) $(<:%.tex=%.toc.bak); fi 
RM = rm -f
OUTDATED = echo "EPS-file is out-of-date!" && false

OPEN = evince

ifeq ($(OS),Darwin)
OPEN = open
endif

all 	: $(TRG)

define run-latex
	  $(COPY);$(LATEX) $<||(egrep -A 3 -i "((Reference|Citation|).*(U|u)ndefined|^!\s)" $(<:%.tex=$(BUILDDIR)%.log);exit 1)
          $(GLOSSARY); ($(MAKEGLOSSARY) $(<:%.tex=%);$(COPY);$(LATEX) $<) ; true
	  egrep -q $(MAKEIDX) $< && ($(MAKEINDEX) $(BUILDDIR)$(<:%.tex=%);$(COPY);$(LATEX) $<) ; true
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
	  -rm -f $(TRG) $(BUILDDIR)*

show	:
	@$(OPEN) $(TRG)

.PHONY	: clean all ps pdf

######################################################################
# Define rules for PDF source files.
%.pdf: %.eps
	epstopdf $< > $(<:%.eps=%.pdf)
