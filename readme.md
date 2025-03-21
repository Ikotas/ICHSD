# ICHSD<br><font size=5>Clean up the Hardsub Sources for Decimation</font>

## Description
<div style=padding-left:20px>

ICHSD is a script for AviSynth that cleans up the hardsub sources for decimation.
</div>

## Features

1. Duplicates one of the duplicate frames and replaces it by overwriting the other to ensure that it is thinned out by decimation.

2. Removal of single-field subtitles.

3. Determination of match codes by pattern match.

4. Automatic removal of combs.

5. Providing a means to manually process further residual combs after automatic processing.

## Syntax and Parameters
<div style=padding-left:20px>

    ICHSD(clip input, int "cr", float "ythresh", int "mthresh", bool "manual",
        int "cr1f", int "cr1t", int "cr2f", int "cr2t", int "cr3f", int "cr3t",
        int "cr4f", int "cr4t", int "cr5f", int "cr5t", bool "show", int "ml",
        bool "ulp", int "suby")
</div>

## Detailed description
<div style=padding-left:20px>

[Japanese](https://ikotas.github.io/ICHSD/)

[English and other languages](https://ikotas-github-io.translate.goog/ICHSD/?_x_tr_sl=ja&_x_tr_tl=en&_x_tr_hl=en) <span style="font-size:80%;">by Google Translate</span>
</div>
