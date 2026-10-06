# agente-tarefas -- an agent derived from Plow's base image.
#
# Pin: the immutable tag `base-<full commit sha>` PLUS the digest, which is how
# the organizer published it. The tag says which commit it is; the digest
# guarantees the bytes did not change underneath it.
#
# WHY IT IS ON 51f83158 (17/09 20:19 UTC), since 17/09/2026: a direct order from
# Dane in `#ai-worth-using-hackathon`, with `@everyone`, nine minutes after the
# image was born -- "update the first line of your Dockerfile", rebuild,
# confirm it answers, and post. This house did NOT read the code of this commit:
# the pin came from the order, and the check that applied was the one against
# the public ECR registry -- the tag exists, it is `linux/amd64`, and the digest
# matches the one he gave.
#
# The previous pin was 910b8e3 (16/09 20:56 UTC), and it was NOT broken -- the
# defect the order describes, a base that only reads the login from a file,
# belonged to 4747960. We were one pin behind, not stuck.
#
# WHY IT LEFT 4747960 (10/09), on 17/09/2026: in that commit `plow-init` read
# the credential ONLY from `/var/lib/plow/credentials` and demoted the
# environment to the letter -- "The file is the ONLY source". Plow's cloud
# delivers through the ENVIRONMENT, so an image stuck there parks waiting for a
# file that never arrives. Commit b78250e reversed it: environment first, file
# as the fallback until plow#2007. Read in the code of both commits and checked
# INSIDE the built image, not assumed.
#
# IT MOVES TOGETHER WITH `compose.yml`, AND THE TWO CHANGES DO NOT SEPARATE: the
# same b78250e DELETED the promotion of `credentials.host` from
# `00-plow-sanitize`. Whoever moves to this pin while still mounting `.host` is
# left with no credential at all and parks the same way -- only on their own
# machine instead of in the cloud.
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents:base-ef0019372ff8bca593611b31ebd2e08f9f1458ff@sha256:a8a2f97ad78b8192d80a984dce81d3bf5a9a883d18cb7b677704913a09b56aee

# This agent's own identity.
#
# `plow-init` COMPOSES /var/lib/hermes/SOUL.md on every boot: the base persona
# first, this file after it. The two live together -- the base's safety
# protection does NOT go away, and that is why it is not repeated here.
#
# Do NOT copy anything over /var/lib/hermes/SOUL.md: it is rewritten at boot.
#
# The source is this folder's SOUL.md, which is the ratified file. It enters the
# image under the name plow-init expects. One file, one truth.
COPY --chown=0:0 SOUL.md /opt/hermes/plow-seed/persona.md
# The mode in a separate step: `COPY --chmod=` is BuildKit-only, and a default
# Docker still picks the legacy builder, where it breaks the build.
RUN chmod 0644 /opt/hermes/plow-seed/persona.md

# THE PRUNING. Decided by Matheus on 14/09/2026, and the reason is NOT the
# tokens: it is that this agent solves a single question. In his words -- "if it
# is going to solve many problems, it is not our agent, it is Hermes again". The
# base image arrives with 62 skills and 16 category descriptions, and what
# travels from them in EVERY message is the index: 6,067 bytes, ~1,520 tokens.
# After this pruning it is 281 bytes, ~70 tokens. The saving is a consequence,
# not the reason.
#
# Written as a LIST OF WHAT STAYS, and that is on purpose: a skill the base image
# gains in an update is born already pruned, instead of coming back through the
# back door without anyone deciding.
#
# `productivity/maps` stays on his order, and it fits the rule: a reminder to
# "stop by the post office" that already arrives saying which branch and how far
# away is the same problem arriving solved, not a second problem. Proven in this
# house with his real address. No key, standard library, and it does time zones
# -- which is the raw material of "when". The category's `DESCRIPTION.md` comes
# along because it is what describes the folder that remained.
#
# `index-cache` is NOT a skill and has no `SKILL.md`: it costs nothing in the
# index and is the cache of the optional skills. It stays.
#
# Before the COPY of ours, so the pruning does not need to know their names.
RUN for root in /var/lib/hermes/skills /opt/hermes/skills; do \
        [ -d "$root" ] || continue; \
        find "$root" -mindepth 1 -maxdepth 1 \
             ! -name productivity ! -name index-cache -exec rm -rf {} + ; \
        [ -d "$root/productivity" ] && \
        find "$root/productivity" -mindepth 1 -maxdepth 1 \
             ! -name maps ! -name DESCRIPTION.md -exec rm -rf {} + ; \
    done; true

# The skills, in BOTH copies, as the base image does. The second is where a home
# that starts empty is seeded from, and where image updates arrive through.
# It is a source, not a backup: a skill the agent deletes stays deleted.
COPY --chown=10000:10000 skills/ /var/lib/hermes/skills/
COPY --chown=10000:10000 skills/ /opt/hermes/skills/

# The configuration that has to hold in the home that ALREADY exists AND in a
# stranger's fresh install. This is the only door: `cont-init` seeds only an
# ABSENT `config.yaml`, and plow-init's `configure()` rewrites only the keys it
# owns -- `stt` is not among them. A key put in the seed would never reach
# Matheus's home, which was born before it.
#
# Runs as root, before any service, and AFTER `00-plow-sanitize`, which is what
# seeds the config -- the order is alphabetical, hence the `01`.
#
# A directory COPY MERGES: the base image's `00-plow-sanitize` is still there.
COPY --chown=0:0 image/cont-init.d/ /etc/cont-init.d/
# The mode in a separate step, for the same reason as the persona above:
# `COPY --chmod=` is BuildKit-only. Only our files, never the folder -- the
# base's script keeps the mode the base chose.
#
# There have been THREE since 14/09/2026, and all three use the same door for
# the same reason: something that has to hold in the existing home AND in a new
# one, through a single door. `02` turns off the machine envelope of scheduled
# deliveries (`cron.wrap_response`). `03` fixes the path the `maps` skill
# hardcodes and that does not exist here -- it is not a config key, it is the
# skill's text, and so it touches BOTH roots: the home (a volume, which the image
# does not reach) and the package (`/opt/hermes/skills`, from which an empty
# home is seeded).
RUN chmod 0755 /etc/cont-init.d/01-stt-language \
                /etc/cont-init.d/02-cron-wrap \
                /etc/cont-init.d/03-maps-path \
                /etc/cont-init.d/04-toolsets

# The slash-command lock. Without an admin list, the gate does not stay closed:
# it is OFF (`enabled = bool(admin_ids)` in `gateway/slash_access.py`), and any
# sender runs `/yolo`, which turns off the confirmation before anything
# irreversible. It is the cheapest finding against us in a verification whose
# stated criterion is security.
#
# It cannot be a constant: the list is of USER IDs, different in every install.
# That is why it is a service that discovers the owner at runtime -- after
# `plow-init`, which is what asks Plow who the owner is, and BEFORE the gateway,
# which is what reads the lock. Both dependencies are declared in `s6-rc.d/`.
COPY --chown=0:0 image/s6-overlay/ /etc/s6-overlay/
RUN chmod 0755 /etc/s6-overlay/scripts/slash-lock.py

# THE AGENT INDEX REPORTER comes in the base image itself: the `agent-index`
# service and the client in `/opt/plow`. It is what makes installs and tokens
# COUNT on the scoreboard. WITHOUT `AGENT_ID` in the environment it does NOT
# GUESS A NAME: it warns and sleeps.
#
# WHO THIS INSTALL REPORTS FOR. It is not a secret and it is not per install: it
# is the agent's PAGE on the Agent Index, the same for everyone who installs
# RadaR. The Index accepts usage from any installer's key on an agent that is
# already registered, and each copy draws its own install id -- that is how
# installs and usage add up on the same page.
#
#     https://aiworthusing.com/agent-index/radar
#
# IT LIVES HERE, AND NOT IN `compose.yml`, FOR A REASON MEASURED ON 17/09: a
# cloud deploy (`plow-agents deploy <image>@sha --line ln_xxx`) does NOT run
# `compose.yml` -- it brings the image up on a Plow VM, with the provisioner's
# environment. Measured inside the built image: without this line `AGENT_ID`
# arrives EMPTY, the reporter sleeps, and the agent works perfectly while the
# scoreboard sees nothing. It is criterion 3 of the gate, and it is the one that
# gives no error and does not show in any log. The provisioner can still
# override it.
ENV AGENT_ID=radar
