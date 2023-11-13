#!/usr/bin/env python

from jsk_data import download_data


def main():
    PKG = 'jsk_teaching_object'

    # download_data(
    #     pkg_name=PKG,
    #     path='sample/data/daily-objects-labels.txt',
    #     url='https://drive.google.com/uc?id=1QkXxdSkIjivgcBWADa6tNZtSQVl-6Pro',
    #     md5='16066e1e9aab0035ee036d65d268e5f3',
    #     extract=False,
    # )

    download_data(
        pkg_name=PKG,
        path='sample/data/2022-05-18-19-02-34-daily-object.bag',
        url='https://drive.google.com/uc?id=1n2eJQuoxC7h488pjd7UMZ_zRXk8n7Iif',
        md5='74f3292c4a53a2725e1ba359ec01cde4',
        extract=False,
    )

    download_data(
        pkg_name=PKG,
        path='sample/data/2023-11-16-drink-object.bag',
        url='https://drive.google.com/uc?id=1z2ikV5e3GzkC-NqYFsWnUcB9H21X7pvy',
        md5='1f99bf6df0bc5da1f7ad3154da8e1b9d',
        extract=False,
    )

    # # industry
    # download_data(
    #     pkg_name=PKG,
    #     path='sample/data/hand_camera_for_box_industrial-image-compressed.bag',
    #     url='https://drive.google.com/uc?id=18diE6jwThqLHb7Vb5TouTxDolY_No3H7',
    #     md5='a41ff9fe04398c5fa17d5dd20bf544ae',
    #     extract=False,
    # )

    # # 2023-03-10
    # download_data(
    #     pkg_name=PKG,
    #     path='sample/data/2023-03-09-18-49-40-image-compressed.bag',
    #     url='https://drive.google.com/uc?id=1DBKcXB5Op7Yxnn56vpi6ub6tNTU5Z2D3',
    #     md5='00df593a26a961d644479cf9d03c41b3',
    #     extract=False,
    # )


if __name__ == '__main__':
    main()
