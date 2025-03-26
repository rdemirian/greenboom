#!/bin/bash

# Start and end dates
start_date=$(date -v-560d +%Y-%m-%d)
end_date=$(date +%Y-%m-%d)
current_date="$start_date"

# Generate a normal-ish random number centered around 10 (range 1–20)
rand_normal() {
  awk -v min=1 -v max=20 '
  BEGIN {
    cmd="openssl rand -hex 4"
    cmd | getline hex1
    close(cmd)
    cmd | getline hex2
    close(cmd)

    u1 = ("0x" hex1) / 4294967295
    u2 = ("0x" hex2) / 4294967295

    z = sqrt(-2 * log(u1)) * cos(2 * 3.1415926 * u2)
    n = int(z * 3.5 + 10.5)

    if (n < min) n = min
    if (n > max) n = max

    print n
  }'
}

# Secure random integer between $1 and $2
rand_range() {
  jot -r 1 "$1" "$2"
}

echo "🚀 Generating commits from $start_date to $end_date..."

while [[ "$current_date" < "$end_date" ]]; do
  # Get day of week (0 = Sunday, 6 = Saturday)
  day_of_week=$(date -j -f "%Y-%m-%d" "$current_date" +%w)

  should_commit=false
  commit_chance=$(rand_range 1 100)

  if [[ "$day_of_week" -eq 0 || "$day_of_week" -eq 6 ]]; then
    # Weekend: 30% chance
    [[ $commit_chance -le 30 ]] && should_commit=true
  else
    # Weekday: 95% chance
    [[ $commit_chance -le 95 ]] && should_commit=true
  fi

  if $should_commit; then
    # 1% chance to go wild: 30–90 commits
    wild_roll=$(rand_range 1 100)
    if [[ $wild_roll -eq 1 ]]; then
      total_commits=$(rand_range 30 90)
      echo "🎉 WILD DAY on $current_date! → $total_commits commits"
    else
      base_commits=$(rand_normal)

      if [[ $base_commits -eq 20 ]]; then
        bonus=$(rand_range 1 7)
        total_commits=$((base_commits + bonus))
        echo "🧨 Max hit! $base_commits + $bonus extra → $total_commits commits"
      else
        total_commits=$base_commits
        echo "📅 $current_date → $total_commits commits"
      fi
    fi

    for i in $(seq 1 $total_commits); do
      echo "$current_date - commit $i" > fake.txt
      git add fake.txt
      GIT_AUTHOR_DATE="$current_date 12:00:00" \
      GIT_COMMITTER_DATE="$current_date 12:00:00" \
      git commit -m "Commit $i on $current_date"
    done
  else
    echo "⛔ $current_date → no commits"
  fi

  current_date=$(date -j -f "%Y-%m-%d" -v+1d "$current_date" +%Y-%m-%d)
done

rm fake.txt
echo "✅ All commits generated!"
