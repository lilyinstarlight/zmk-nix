{ fetchPypi
, lib
, python3Packages
}:
with python3Packages;
buildPythonApplication rec {
  pname = "adafruit-nrfutil";
  version = "0.5.3.post16";
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-tyED3I5Q+SlR9RL8K28sYh2sFhRTHd+MC+OxPQIOJK0=";
  };
  build-system = [
    nose
    behave
  ];
  dependencies = [
    pyserial
    click
    ecdsa
  ];
  # Tests were not updated to work on Python3, package does not support Python2.
  doCheck = false;
  meta = with lib; {
    description = "Python 3 version of Nordic Semiconductor nrfutil utility and Python library (modified by Adafruit)";
    # NORDIC SEMICONDUCTOR STANDARD SOFTWARE LICENSE AGREEMENT
    # Ref: https://github.com/adafruit/Adafruit_nRF52_nrfutil/issues/41
    #
    # Of note:
    # 4. This software must only be used in or with a processor manufactured by Nordic
    # Semiconductor ASA, or in or with a processor manufactured by a third party that
    # is used in combination with a processor manufactured by Nordic Semiconductor.
    license = [ licenses.bsd3 licenses.mit licenses.unfreeRedistributable ];
    platforms = platforms.all;
    maintainers = with maintainers; [];
  };
}
