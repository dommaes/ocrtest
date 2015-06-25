# ocrtest

ocrtest is a small bash shell script to test different OCR suites on Linux.
It was written on Ubuntu 15.04 to help test [OCRFeeder](https://wiki.gnome.org/action/show/Apps/OCRFeeder?action=show&redirect=OCRFeeder) and [ocropus](https://github.com/tmbdev/ocropy) during a college project.

## Usage

You can run a test by typing
```
./ocrtest.sh 1 [IMAGE]
```
into your preferred shell on Linux.
The number after the call indicates the quantity of test runs to perform.
[IMAGE] is a placeholder for any image file. Its format has to be supported by both OCRFeeder and ocropus.
You can specify up to 9 images to perform the test with.
