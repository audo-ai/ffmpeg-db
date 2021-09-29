from setuptools import setup

setup(
    name='ffmpeg-db',
    version='0.3.0',
    description='Dataset/library of parsed ffmpeg codec information',
    url='https://github.com/audo-ai/ffmpeg-db',
    author='Matthew D. Scholefield',
    author_email='matthew331199@gmail.com',
    classifiers=[
        'Development Status :: 3 - Alpha',

        'Intended Audience :: Developers',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
    ],
    keywords='ffmpeg db',
    packages=['ffmpeg_db'],
    package_data={
        'ffmpeg_db': ['data/*.json']
    },
    install_requires=[],
)
