set -e

TEXFILE_DIR=/Users/mlevental/dev_projects/school_work/spring2021/CMSC32900/
cp latexpand $TEXFILE_DIR/
export PROJECTNAME=quantumtensors

TEXFILE=main.tex
BIBLIO=biblio.bib
FLOATS_TEXFILE=floats
export FLOATS_LABELED=$TEXFILE_DIR/${FLOATS_TEXFILE}_labeled.pdf
echo $FLOATS_LABELED

pushd $TEXFILE_DIR

perl latexpand $TEXFILE > newarticle.tex
TEXFILE=newarticle.tex

sed -i bk 's/\begin{figure}\[.*\]/\begin{figure*}/g' $TEXFILE 
sed -i bk 's/\begin{figure}/\begin{figure*}/g' $TEXFILE 
sed -i bk 's/\end{figure}/\end{figure*}/g' $TEXFILE 
sed -i bk 's/\\inputencoding{utf8}//g' $TEXFILE
sed -i bk 's/\\inputencoding{latin9}//g' $TEXFILE
sed -i bk 's/\bibliographystyle{.*}/\bibliographystyle{apalike}/g' $TEXFILE

sed 's/\begin{document}/\usepackage[active,floats,tightpage,showlabels]{preview}\\begin{document}/' $TEXFILE > ${FLOATS_TEXFILE}_labeled
pdflatex -shell-escape ${FLOATS_TEXFILE}_labeled


sed 's/\begin{document}/\usepackage[active,floats,tightpage]{preview}\\begin{document}/' $TEXFILE > $FLOATS_TEXFILE
# sed -i bk 's/caption/caption*/g' $FLOATS_TEXFILE

pdflatex -shell-escape $FLOATS_TEXFILE
if [ ${#BIBLIO} -ge 1 ]; then
    bibtex $FLOATS_TEXFILE
fi
pdflatex -shell-escape $FLOATS_TEXFILE
pdflatex -shell-escape $FLOATS_TEXFILE

popd


if test -f $TEXFILE_DIR/$FLOATS_TEXFILE.pdf; then
    mkdir -p ../../images/$PROJECTNAME
    gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r600 -sOutputFile="../../images/$PROJECTNAME/float%03d.png" $TEXFILE_DIR/$FLOATS_TEXFILE.pdf
fi

MD_FNAME="../$(date '+%Y-%m-%d')-$PROJECTNAME.md"

if [ ${#BIBLIO} -ge 1 ]; then
pandoc --filter=filter.py \
    --mathjax \
    -f latex \
    --number-sections \
    -t gfm+tex_math_dollars+footnotes+gfm_auto_identifiers+implicit_header_references+pipe_tables+hard_line_breaks \
    -s $TEXFILE_DIR/$TEXFILE \
    --bibliography $TEXFILE_DIR/$BIBLIO \
    --citeproc \
    --metadata link-citations=true \
    --metadata excerpt_separator="<!--more-->" \
    --metadata reference-section-title="References" \
    --csl=springer-mathphys-brackets.csl \
    -o $MD_FNAME
    # -t native > out_native.json
else
pandoc --filter=filter.py \
    --mathjax \
    -f latex \
    --number-sections \
    -t gfm+tex_math_dollars+footnotes+gfm_auto_identifiers+implicit_header_references+pipe_tables+hard_line_breaks \
    -s $TEXFILE_DIR/$TEXFILE \
    --metadata excerpt_separator="<!--more-->" \
    -o $MD_FNAME
    # -t native > out_native.json
fi

python mathbf_fix.py $MD_FNAME

pushd $TEXFILE_DIR

rm ${TEXFILE}*
rm ${FLOATS_TEXFILE}_labeled*
rm $FLOATS_TEXFILE*

popd