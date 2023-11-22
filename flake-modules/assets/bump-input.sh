INPUTNAME=${1}
GIT_ROOT=$(git rev-parse --show-toplevel)

echo "⬆️ Bumping input ${INPUTNAME}"
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
    nix flake lock --update-input "${INPUTNAME}"
    echo "----"

    echo " Adding a commit"
    (cd "$GIT_ROOT" && git commit --no-verify flake.lock -m "[ci]: bumping input ${INPUTNAME}") # no-verify prevents pre-commit hooks, not needed here
fi

echo "✅All done!"
exit
