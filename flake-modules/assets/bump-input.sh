INPUTNAME=${1:-}
GIT_ROOT=$(git rev-parse --show-toplevel)

if [[ -z $INPUTNAME ]]; then
    echo "⬆️ Bumping all inputs"
else
    echo "⬆️ Bumping input ${INPUTNAME}"
fi

if [[ $(cd "$GIT_ROOT" && git status --porcelain flake.lock) ]]; then
    echo "❌flake.lock has uncommitted changes. Commit before proceeding"
    exit 1
else
    # TODO: figure out how lazygit does the WIP commits
    if ! git diff --cached --quiet; then
        echo "⚠️ WARN: unstaging files"
        git reset
    fi
    echo "❄️ Nix flake output:"
    echo "----"
    if [[ -z $INPUTNAME ]]; then
        nix flake update
    else
        nix flake lock --update-input "${INPUTNAME}"
    fi
    echo "----"

    echo " Adding a commit"
    if [[ -z $INPUTNAME ]]; then
        (cd "$GIT_ROOT" && git commit --no-verify flake.lock -m "[ci]: bumping inputs") # no-verify prevents pre-commit hooks, not needed here
    else
        (cd "$GIT_ROOT" && git commit --no-verify flake.lock -m "[ci]: bumping input ${INPUTNAME}") # no-verify prevents pre-commit hooks, not needed here
    fi
fi

echo "✅All done!"
exit
