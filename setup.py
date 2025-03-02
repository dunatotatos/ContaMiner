#!/usr/bin/env python3
"""
Setup tools installation.

Run this script to install or upgrade contaminer.
"""

import os
from setuptools import setup, find_packages

REQUIREMENTS = open(os.path.join(os.path.dirname(__file__),
                                 'requirements.txt')).readlines()
setup(name='contaminer',
      version='1.0.1',
      install_requires=REQUIREMENTS,
      packages=find_packages(),
      scripts=['contaminer/scripts/contaminer'],
      package_data={
          "contaminer.data": [
              "contabase.yaml",
              "job_template.sh",
              "job_template.sbatch"
          ]
      },
      author="Arnaud Hungler",
      description=("Rapid automated large-scale detection of contaminant "
                   "crystals"),
      author_email="arnaud@hungler-consulting.ch",
      url="https://github.com/StruBE-KAUST/ContaMiner",
      )
