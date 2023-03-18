ARG base
FROM ${base}

RUN apt-get update && apt-get install --yes --no-install-recommends \
        python3 python3-pip python3-setuptools python3-wheel twine \
        flake8 python3-flake8-docstrings python3-pytest-flake8 \
        mypy mypy-doc pylint pylint-doc \
        python3-pytest nox tox tox-delay
ENV PYTHONDONTWRITEBYTECODE=1
