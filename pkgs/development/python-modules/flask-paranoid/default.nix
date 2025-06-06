{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flask,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "flask-paranoid";
  version = "0.3.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "miguelgrinberg";
    repo = "flask-paranoid";
    rev = "v${version}";
    hash = "sha256-tikD8efc3Q3xIQnaC3SSBaCRQxMI1HzXxeupvYeNnE4=";
  };

  postPatch = ''
    # tests have a typo in one of the assertions
    substituteInPlace tests/test_paranoid.py --replace "01-Jan-1970" "01 Jan 1970"
  '';

  propagatedBuildInputs = [ flask ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "flask_paranoid" ];

  meta = with lib; {
    homepage = "https://github.com/miguelgrinberg/flask-paranoid/";
    description = "Simple user session protection";
    license = licenses.mit;
    maintainers = with maintainers; [ gador ];
  };
}
