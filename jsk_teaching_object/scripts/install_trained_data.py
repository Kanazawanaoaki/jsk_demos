#!/usr/bin/env python

from __future__ import print_function

import argparse
import multiprocessing

import jsk_data


def download_data(*args, **kwargs):
    p = multiprocessing.Process(
        target=jsk_data.download_data,
        args=args,
        kwargs=kwargs)
    p.start()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-v', '--verbose', dest='quiet', action='store_false')
    args = parser.parse_args()
    quiet = args.quiet

    PKG = 'jsk_teaching_object'

    # download_data(
    #     pkg_name=PKG,
    #     path='trained_data/20220420-120316-dataset-20-daily-objects.tflite',
    #     url='https://drive.google.com/uc?id=1AvjThabb3ODTPC5SaAOKrRZ54-e3O8f8',
    #     md5='cfff1e0c6709c2fd4b67401232238246',
    #     quiet=quiet,
    # )

    # # for (rau, ba25, fan)
    # download_data(
    #     pkg_name=PKG,
    #     path='trained_data/2023-03-01/model.pth',
    #     url='https://drive.google.com/uc?id=1h5HKJ7FyHAgH72IxPka6-1oDyn5mKHgJ',
    #     md5='6f1dda26737242398515b219a684fb22',
    #     quiet=quiet,
    # )
    # download_data(
    #     pkg_name=PKG,
    #     path='trained_data/2023-03-01/class_names.txt',
    #     url='https://drive.google.com/uc?id=14iU7yoHtdOiH2Yi3M3m98Tt4jfTWV-Dm',
    #     md5='5510e1c346ae9648594a3cf28f89162e',
    #     quiet=quiet,
    # )

    # # 2023-03-10
    # download_data(
    #     pkg_name=PKG,
    #     path='trained_data/2023-03-10/output_tflite_graph_edgetpu.tflite',
    #     url='https://drive.google.com/uc?id=1zJnYti2lMsteI34X48CFAPRGSk80H6R8',
    #     md5='0ac42d2a5af44533ad5bcbfc8a596e6e',
    #     quiet=quiet,
    # )

    # download_data(
    #     pkg_name=PKG,
    #     path='trained_data/2023-03-10/labels.txt',
    #     url='https://drive.google.com/uc?id=1k9LQ0Kx70-pUiDPidGCOdy6lnusAD1mQ',
    #     md5='03c47c34ed1d121fbb653fc5bab2782b',
    #     quiet=quiet,
    # )

    download_data(
        pkg_name=PKG,
        path='trained_data/yolo8/2023-11-13-drink-objects.pt',
        url='https://drive.google.com/uc?id=1tRgNWLeijTQDFIKC08NNQPz1jbU74wX9',  # NOQA
        md5='c314689832c141341e0c7b2bc4cf7d93',
    )


if __name__ == '__main__':
    main()
