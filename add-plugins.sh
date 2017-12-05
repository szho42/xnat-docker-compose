#!/bin/bash

wget --quiet --no-cookies https://gitlab.erc.monash.edu.au/mbi-image/xnat-non-dicom-upload-plugin/builds/1251/artifacts/file/out/artifacts/non-dicom-uploader/non-dicom-uploader.jar -O /data/xnat/home/plugins/non-dicom-uploader.jar

docker pull manishkumr/xnat-qc-pipeline
