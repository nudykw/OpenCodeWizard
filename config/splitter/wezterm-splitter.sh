#!/bin/sh
# wezterm-splitter — creates 3-pane layout: gitui(optional) | shared terminal + opencode
set -e

# Cleanup: убить child-панели при закрытии вкладки или выходе из opencode
# Вызывается по EXIT (нормальный выход) и INT/TERM/HUP (X на вкладке)
cleanup() {
    wezterm cli kill-pane --pane-id "$SHARED_PANE" 2>/dev/null || true
    wezterm cli kill-pane --pane-id "$LEFT_PANE" 2>/dev/null || true
}
trap cleanup EXIT INT TERM HUP

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

# 1. Split left 40% — создаёт левую колонку, возвращает её ID
LEFT_PANE=$(wezterm cli split-pane --left --percent 40)

# 2. Split левой колонки снизу 30% — общий терминал
SHARED_PANE=$(wezterm cli split-pane --pane-id "$LEFT_PANE" --bottom --percent 30)

# 3. Сохранить ID shared терминала (уникален для каждой панели WezTerm)
echo "$SHARED_PANE" > "/tmp/wezterm-shared-pane-for-$WEZTERM_PANE"

# 4. Если есть git — запустить gitui в верхней-левой панели
if [ -n "$GIT_ROOT" ]; then
  printf 'cd %s && gitui\n' "$GIT_ROOT" | wezterm cli send-text --no-paste --pane-id "$LEFT_PANE"
fi

# 5. Запустить opencode — cleanup выполнится через trap при выходе
# "|| true" нужен, чтобы set -e не прервал скрипт при ошибке opencode
opencode -m opencode/deepseek-v4-flash-free || true
