#!/bin/bash

SIMPLE_UPLOAD_LATEST_RELEASE=$(curl -s https://api.github.com/repos/mbi-image/xnat-simple-upload-plugin/releases/latest | grep browser_download_url | cut -d '"' -f 4)
echo $SIMPLE_UPLOAD_LATEST_RELEASE
sudo wget --quiet --no-cookies $SIMPLE_UPLOAD_LATEST_RELEASE -O plugins/non-dicom-uploader.jar

docker pull manishkumr/xnat-qc-pipeline
