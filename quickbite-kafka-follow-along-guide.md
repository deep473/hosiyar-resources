# QuickBite + Kafka — Follow-Along Guide (Demos 1–8)

Companion to **"Kafka in Real Code"** on Hosiyar.

This guide walks you through running the QuickBite project yourself and reproducing all eight demos from the video. Commands are given for **macOS / Linux** and **Windows** side by side.

**Code:** the GitHub link is in the video description.

---

## What you need before you start

| | |
|---|---|
| **Java 17 or newer** | Check with `java -version` |
| **Apache Kafka 4.x, running** | Installed in the previous video. One broker, KRaft mode — no ZooKeeper, no Docker |
| **IntelliJ IDEA** | Community Edition is enough |

You do **not** need Maven installed — the project includes the Maven wrapper.

If you haven't installed Kafka yet, watch **"Kafka on Your Laptop"** first. It's three commands.

---

## What the project contains

Five small Java files. That's the whole application.

| File | What it does |
|---|---|
| `OrderApi.java` | **The producer.** One endpoint, `POST /orders`, that turns a request into a Kafka event |
| `NotificationService.java` | **Consumer #1**, in `notification-group`. Pretends to send an email |
| `AnalyticsService.java` | **Consumer #2**, in `analytics-group`. Counts orders |
| `DeadLetterConfig.java` | Retries and the dead letter topic. Switched off by default |
| `QuickbiteApplication.java` | Starts the application |

Plus `application.yml` for settings, and a script to fire several orders at once.

There's no database and no service layers on purpose. Everything you see is about Kafka.

---

# PART 1 — Setting up

## 1.1 Get the project into IntelliJ

**Option A — straight from IntelliJ**
Welcome screen → **Get from VCS** → paste the GitHub link → Clone.
(If a project is already open: File → New → Project from Version Control.)

**Option B — clone first**
```bash
git clone <link from the description>
```
Then File → Open in IntelliJ and select the folder.

When IntelliJ asks, **trust the project**, and wait for Maven to finish importing (the status bar shows progress; the first time it downloads Spring, so give it a minute).

Check the JDK: **File → Project Structure → Project → SDK** must be 17 or newer.

## 1.2 Create four run configurations

These are the heart of the setup. Go to **Run → Edit Configurations**, create the first one, then right-click → **Copy Configuration** for the rest.

All four run the same class: `QuickbiteApplication`.

| Name | What to set | Used in |
|---|---|---|
| **Copy A** | nothing — defaults give port 8081, instance A | Demos 1, 2, 3, 4, 5, 7 |
| **Copy B** | **Environment variables:** `PORT=8082;INSTANCE=B`<br>**Modify options → ✅ Allow multiple instances** | Demos 3, 4 |
| **A — dedup on** | **Program arguments:** `--app.dedup.enabled=true` | Demo 6 |
| **A — DLT on** | **Program arguments:** `--app.dlt.enabled=true` | Demo 8 |

> **Don't skip "Allow multiple instances" on Copy B.** Without it, IntelliJ stops copy A when you start copy B, and you end up with one running app instead of two — which makes Demo 3 impossible.

**Tip:** right-click each tab in the Run window → **Pin Tab**, so re-running an app doesn't wipe the output you're looking at.

## 1.3 Open two terminal tabs inside IntelliJ

Open the Terminal tool window (**⌥F12** on macOS, **Alt+F12** on Windows) and create a second tab with the **+** button. Right-click → Rename Session to name them.

| Tab | Folder | Used for |
|---|---|---|
| **kafka** | your Kafka folder | Starting Kafka, creating topics, inspecting groups |
| **orders** | the `quickbite-kafka` folder | Firing orders |

## 1.4 Start Kafka

In the **kafka** tab (or a separate terminal — Kafka needs a window of its own):

**macOS / Linux**
```bash
bin/kafka-server-start.sh config/server.properties
```
**Windows (PowerShell)**
```powershell
bin\windows\kafka-server-start.bat config\server.properties
```

Wait for a line containing `Kafka Server started`. Leave this running for the whole session.

## 1.5 Create the two topics

In a terminal tab in your Kafka folder:

**macOS / Linux**
```bash
bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic orders --partitions 3 --replication-factor 1

bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic orders.DLT --partitions 3 --replication-factor 1
```
**Windows (PowerShell)**
```powershell
bin\windows\kafka-topics.bat --bootstrap-server localhost:9092 `
  --create --topic orders --partitions 3 --replication-factor 1

bin\windows\kafka-topics.bat --bootstrap-server localhost:9092 `
  --create --topic orders.DLT --partitions 3 --replication-factor 1
```

`already exists` is fine — it just means you created it earlier.

> **`orders.DLT` must have 3 partitions.** When a record can't be processed, Spring parks it in the dead letter topic **at the same partition number** it came from. If the DLT has fewer partitions, Demo 8 will fail.

## 1.6 Make the helper script runnable

**macOS / Linux** — in the **orders** tab:
```bash
chmod +x scripts/fire-orders.sh
```
**Windows** — allow scripts in this terminal window only:
```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

---

## You never edit code during the demos

Worth saying clearly, because it's easy to assume otherwise:

- **`application.yml` stays exactly as it is.** Both switches stay `false`. The run configurations pass `--app.dedup.enabled=true` and `--app.dlt.enabled=true` on the command line, which override the file at startup.
- **No Java file is edited.** The failure scenarios are triggered by the **data you send** — an order with `amount=CRASH` or `amount=FAIL`.

Everything you'll see is Kafka behaving the way Kafka behaves.

---

## Quick reference — what each demo needs

| Demo | What it shows | Run configuration | Copy B running? |
|---|---|---|---|
| 1 | One order reaching two groups | Copy A | no |
| 2 | Keys decide the partition | Copy A | no |
| 3 | Two instances split the work | Copy A **+** Copy B | yes |
| 4 | Rebalancing when one dies | Copy A (+ B, killed) | yes → no |
| 5 | The same email sent twice | Copy A | **no** |
| 6 | The duplicate ignored | A — dedup on | **no** |
| 7 | A bad record silently skipped | Copy A | **no** |
| 8 | A bad record safely parked | A — DLT on | **no** |

**After Demo 4, stop copy B and leave it stopped.** From Demo 6 onwards you restart copy A with a switch turned on. If copy B is still running *without* that switch, an order landing on B's partitions will ignore the switch, and the demo will look broken for no reason.

**Order IDs:** every failure demo uses a new ID on purpose. Once an order has been processed and its position committed, Kafka won't deliver it again — so reusing an ID won't reproduce the scenario.

---

# PART 2 — The demos

Start copy A before Demo 1: select **Copy A** in the run configuration dropdown and click Run. Wait until you see both groups report `partitions assigned`.

In every demo below, run the order commands in the **orders** terminal tab. On Windows, replace `./scripts/fire-orders.sh 4471` with `.\scripts\fire-orders.ps1 4471`.

---

## Demo 1 — One order, two groups

**What this shows:** a single event travelling from an HTTP request into Kafka and out to two separate consumers.

**Run it**

macOS / Linux:
```bash
curl -X POST "localhost:8081/orders?orderId=4471"
```
Windows (PowerShell — note `curl.exe`, not `curl`):
```powershell
curl.exe -X POST "http://localhost:8081/orders?orderId=4471"
```

**Expected output**

In the terminal:
```
sent: 4471|PLACED|450
```
In copy A's console:
```
[A] notification-group  p=1  off=0  key=4471  -> email sent
[A]    analytics-group  p=1  off=0  -> counted
```

**What it means**

- The response came back **immediately**, before either consumer did anything. The producer hands the event to Kafka and moves on — it doesn't wait for anyone. That's the decoupling the whole series is about.
- **Both groups received the same record.** Neither took it away from the other. A traditional queue would have handed it to one consumer and deleted it.
- Reading the log line: instance `A`, partition `1`, offset `0`, key `4471`.

*Your partition number may differ from the example — that's normal.*

---

## Demo 2 — Keys decide the partition

**What this shows:** the message key controls which partition a record lands in, and every event for one order stays together.

**Run it**
```bash
./scripts/fire-orders.sh 4471 4472 4473 4474
./scripts/fire-orders.sh 4471 4471 4471
```

**Expected output**
```
[A] notification-group  p=1  off=1  key=4471  -> email sent
[A] notification-group  p=0  off=0  key=4472  -> email sent
[A] notification-group  p=2  off=0  key=4473  -> email sent
[A] notification-group  p=1  off=2  key=4471  -> email sent
[A] notification-group  p=1  off=3  key=4471  -> email sent
```

**What it means**

- **Different keys spread across partitions.** That spread is what lets Kafka process many records in parallel.
- **Every `4471` line shows the same partition number.** Kafka hashes the key to choose a partition, so the same key always goes to the same one. That's how all of one order's events — placed, paid, shipped — stay in the right order.
- **Offsets count up separately in each partition.** Partition 1 has its own 0, 1, 2, 3; partition 0 has its own. An offset only means something *within* a partition.

In the code, this is a single argument:
```java
kafka.send("orders", orderId, event);
//                   ^^^^^^^ the key
```

---

## Demo 3 — Two copies split the work

**What this shows:** how a consumer group divides partitions between running instances.

**Run it**

1. Switch the run configuration dropdown to **Copy B** and click Run. (Copy A keeps running.)
2. **Put the two consoles side by side:** right-click the "Copy B" tab in the Run window → **Split and Move Right**.
3. Watch copy A's console — it reports partitions being revoked, then a smaller set assigned.
4. **Wait about 5 seconds** for the group to settle.
5. Fire six orders:
   ```bash
   ./scripts/fire-orders.sh 5001 5002 5003 5004 5005 5006
   ```

**Expected output**

During the rebalance, something like:
```
notification-group: partitions revoked:  [orders-0, orders-1, orders-2]
notification-group: partitions assigned: [orders-2]           <- copy A
```
and in copy B:
```
notification-group: partitions assigned: [orders-0, orders-1]  <- copy B
```

Then each of the six orders appears in **exactly one** of the two consoles — never both.

**What it means**

- Both copies declare the same `groupId`, so Kafka treats them as **one team** and gives each partition to exactly one member.
- Three partitions, two consumers — so one copy owns two partitions and the other owns one. If you started a fourth copy, it would sit idle: **partition count is the ceiling** on how far a group can scale.
- No order is handled twice. Nobody gets two emails.

**Something you'll probably notice:** `notification-group` and `analytics-group` may split the partitions *differently* — copy A might own one partition in one group and two in the other. That's correct. Each group rebalances independently and has no idea the other exists.

**Check it from outside** — in the **kafka** terminal tab:

macOS / Linux:
```bash
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
  --describe --group notification-group
```
Windows:
```powershell
bin\windows\kafka-consumer-groups.bat --bootstrap-server localhost:9092 `
  --describe --group notification-group
```

| Column | What it tells you |
|---|---|
| `PARTITION` + `CONSUMER-ID` | Which copy owns which partition |
| `CURRENT-OFFSET` | How far this **group** has read |
| `LOG-END-OFFSET` | How far the partition actually goes |
| `LAG` | The difference — how far behind the group is |

---

## Demo 4 — Rebalancing when an instance dies

**What this shows:** the group healing itself when a consumer disappears.

**Run it**

1. Click into **copy B's console** and press the red **stop** square (⌘F2 / Ctrl+F2).
2. Watch copy A's console — it is assigned copy B's partitions back.
3. Fire more orders:
   ```bash
   ./scripts/fire-orders.sh 6001 6002 6003 6004
   ```
4. *(Optional)* Start copy B again and watch the split return.
5. **Stop copy B and leave it stopped for the rest of the demos.**

**Expected output**

After B stops, copy A logs `partitions assigned: [orders-0, orders-1, orders-2]`, and all four new orders appear in copy A's console.

**What it means**

- Kafka noticed copy B stopped sending heartbeats, declared it gone, and reassigned its partitions — **you wrote no code for this**.
- Nothing was left unread. Records that would have gone to copy B are now handled by copy A.
- Restart B and Kafka rebalances again. Instances can come and go freely.

---

## Demo 5 — The same email, sent twice

**What this shows:** the most important lesson in the whole series — **at-least-once delivery**.

**Make sure:** copy A is running on the plain **Copy A** configuration, and **copy B is stopped**.

**What the code does:** for an order ending in `|CRASH`, the listener sends the email, then throws an exception — *after* the side effect, *before* Kafka has been told the record is done.

**Run it**

macOS / Linux:
```bash
AMOUNT=CRASH ./scripts/fire-orders.sh 7001
```
Windows:
```powershell
.\scripts\fire-orders.ps1 7001 -Amount CRASH
```

**Expected output**
```
[A] notification-group  p=2  off=5  key=7001  -> email sent
[A] notification-group  p=2  off=5  key=7001  -> CRASHED after sending, before committing
[A] notification-group  p=2  off=5  key=7001  -> email sent
```
(Spring also logs the exception in between — that's expected, not a problem with your setup.)

**What it means**

- Look at the **offset**: `off=5` on the first line and `off=5` again on the last. Kafka delivered **the same record twice**.
- Why? Spring Kafka commits the offset *after* your listener method finishes. The method threw an exception, so the bookmark never moved — and the record was delivered again from the last committed position.
- The customer received **two identical emails**.
- Nothing is broken. This is **at-least-once delivery**, and it's the default in almost every Kafka system.

> **Your consumer will process the same message twice. Not might. Will.**

The alternative — committing *before* doing the work — means a crash loses the record silently, with no error anywhere. Duplicates are the better problem to have.

---

## Demo 6 — Making the duplicate harmless

**What this shows:** idempotency — you don't prevent duplicates, you make repeating them harmless.

**Run it**

1. Stop copy A (red square).
2. Switch the dropdown to **A — dedup on**. Click Run. Wait for the partitions to be assigned.
3. Fire a **new** crashing order:
   ```bash
   AMOUNT=CRASH ./scripts/fire-orders.sh 7002
   ```
   Windows: `.\scripts\fire-orders.ps1 7002 -Amount CRASH`

**Expected output**
```
[A] notification-group  p=0  off=3  key=7002  -> email sent
[A] notification-group  p=0  off=3  key=7002  -> CRASHED after sending, before committing
[A] notification-group  p=0  off=3  key=7002  -> duplicate ignored
```

**What it means**

- Kafka **still redelivered** the record — same offset, twice. That did not change, and it never will.
- The difference is what the consumer did with it: it checked whether it had already handled this exact record and skipped it. **One email.**
- Think of a lift call button. Press it five times — one lift arrives. The extra presses change nothing.

The code:
```java
String eventId = key + "-" + offset;

if (dedupEnabled && handled.contains(eventId)) {
    log(partition, offset, key, "duplicate ignored");
    return;
}

// ... do the work ...
handled.add(eventId);   // remember it AFTER success
```

**The order matters.** We record the ID *after* the work succeeds. If we recorded it first and the work then failed, the retry would be skipped and the email would never be sent at all.

**Important — this is a teaching version.** In a real system:
- That in-memory `Set` would be a **database table** of processed IDs, usually with a unique constraint. An in-memory set forgets everything on restart and isn't shared between instances.
- `key + offset` works here, but real systems put a **proper event ID inside the message**.
- Often the best fix is to design the operation so repeating is naturally safe: *"set status = SHIPPED"* is safe to run twice; *"add 10 loyalty points"* is not.

*Use a new order ID (7002, not 7001) — 7001 was already completed in Demo 5, so Kafka won't deliver it again.*

---

## Demo 7 — A record that can never succeed

**What this shows:** what happens to a "poison message" when you haven't told Spring what to do with it.

**What the code does:** an order ending in `|FAIL` throws an exception **before** any email is sent, every single time. Retrying can never help.

**Run it**

1. Stop copy A.
2. Switch the dropdown back to **Copy A** (plain, no switches). Run. Wait for the partitions.
3. Fire the poison order:
   ```bash
   AMOUNT=FAIL ./scripts/fire-orders.sh 9999
   ```
   Windows: `.\scripts\fire-orders.ps1 9999 -Amount FAIL`

**Expected output**

The same offset fails over and over — roughly ten attempts in quick succession — then an error line and silence:
```
[A] notification-group  p=1  off=8  key=9999  -> FAILED - cannot process this record
[A] notification-group  p=1  off=8  key=9999  -> FAILED - cannot process this record
...
ERROR  Backoff exhausted for orders-1@8
```
*(The exact wording varies by version.)*

**What it means**

- The record is **malformed for our code** — no amount of retrying will fix it.
- Spring retried, gave up, and **skipped** it. The consumer moved on.
- That order was **never processed, and nothing kept a copy of it.** It's gone.
- Notice what *didn't* happen: the partition wasn't blocked forever. If Spring had kept retrying, every record behind this one would have waited too — that's called **head-of-line blocking**, and it's worse.

Losing the record isn't acceptable either. Demo 8 fixes it.

---

## Demo 8 — The dead letter topic

**What this shows:** the same poison record being **parked** instead of lost, while everything behind it keeps moving.

**What the code does:** `DeadLetterConfig` only exists when `app.dlt.enabled=true`. It retries twice, one second apart, then publishes the record to `orders.DLT`.

```java
return new DefaultErrorHandler(
        new DeadLetterPublishingRecoverer(template),
        new FixedBackOff(1000L, 2));   // 2 retries, 1 second apart
```

**Run it**

1. Stop copy A.
2. Switch the dropdown to **A — DLT on**. Run. Wait for the partitions.
3. Fire a bad order, then immediately a good one:
   ```bash
   AMOUNT=FAIL ./scripts/fire-orders.sh 9998
   ./scripts/fire-orders.sh 9997
   ```
   Windows:
   ```powershell
   .\scripts\fire-orders.ps1 9998 -Amount FAIL
   .\scripts\fire-orders.ps1 9997
   ```
4. Look inside the dead letter topic, in the **kafka** terminal tab:

   macOS / Linux:
   ```bash
   bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 \
     --topic orders.DLT --from-beginning
   ```
   Windows:
   ```powershell
   bin\windows\kafka-console-consumer.bat --bootstrap-server localhost:9092 `
     --topic orders.DLT --from-beginning
   ```
   Press `Ctrl+C` when you've seen it.

**Expected output**

In copy A's console — three attempts about a second apart, then the good order right behind it:
```
[A] notification-group  p=0  off=4  key=9998  -> FAILED - cannot process this record
[A] notification-group  p=0  off=4  key=9998  -> FAILED - cannot process this record
[A] notification-group  p=0  off=4  key=9998  -> FAILED - cannot process this record
[A] notification-group  p=2  off=6  key=9997  -> email sent
```
In the DLT consumer:
```
9998|PLACED|FAIL
```

**What it means**

- **Three attempts**, about a second apart: the first try plus two retries. Retries exist because many failures are temporary — a database blip, a brief network problem. Those succeed on the second try.
- After the retries, the record was **published to `orders.DLT`** instead of being dropped. Compare with Demo 7, where the identical record simply vanished.
- Order `9997`, right behind it, **processed normally**. The partition was never blocked.
- Think of a sorting office: a letter with an unreadable address goes into the problem pile, and the queue keeps moving. Someone deals with the problem pile later.

In production, the dead letter topic is monitored. You inspect what landed there, fix the data or the bug, and replay the records.

---

# PART 3 — If something goes wrong

| What you see | Why | Fix |
|---|---|---|
| Starting copy B stops copy A | "Allow multiple instances" not ticked | Copy B config → Modify options → tick it |
| Only one console visible in Demo 3 | Run window isn't split | Right-click the Copy B tab → Split and Move Right |
| One console receives nothing in Demo 3 | Your six keys all hashed to the other copy's partitions, or you fired too soon | Wait 5 seconds after B starts; fire a few more IDs (5007, 5008…) |
| No crash in Demo 5 or 6 | You reused an order ID that was already processed | Use a fresh ID |
| Demo 6 still sends two emails | Wrong run configuration, or copy B still running | Use **A — dedup on**; stop copy B |
| Demo 8 shows ~10 rapid failures | You're on the plain **Copy A** config | Switch to **A — DLT on** |
| `orders.DLT` stays empty | Same as above | Restart with **A — DLT on** |
| Error publishing to `orders.DLT` | Topic missing or has fewer than 3 partitions | Recreate it with `--partitions 3` |
| `Connection to node -1 could not be established` | Kafka isn't running | Start the broker |
| `No qualifying bean of type KafkaTemplate` | Wrong dependency | Spring Boot 4 needs `spring-boot-starter-kafka`, not `spring-kafka` on its own |
| `Port 8081 was already in use` | An old copy is still running | Stop it in the Run window (check the Services tool window too) |
| `permission denied: ./scripts/fire-orders.sh` | Script isn't executable | `chmod +x scripts/fire-orders.sh` |
| PowerShell won't run the `.ps1` script | Execution policy | `Set-ExecutionPolicy -Scope Process Bypass` |
| `curl` behaves oddly on Windows | In PowerShell, `curl` is a different command | Use `curl.exe` |

## Starting completely fresh

If your offsets have drifted and you want a clean slate: stop everything, then delete Kafka's data directory (the path is in `log.dirs` in `config/server.properties`), re-run the `kafka-storage.sh format` step from the previous video, start the broker, and recreate both topics.

---

# PART 4 — Try these yourself

The demos show what happens. These questions make sure you know *why*:

1. **Start a fourth copy of the app** (a new run configuration on port 8084). Watch what `--describe` says about `notification-group`. Why does one consumer end up with nothing to do?
2. **Fire the same order ID twenty times** and watch the partition column. Why is it always the same partition?
3. **Run a console consumer with a brand-new group id and `--from-beginning`.** Why do you get every order from the entire session, even ones that were processed long ago?
4. **In Demo 6, move `handled.add(eventId)` to *before* the work instead of after.** Send a CRASH order. What goes wrong, and why is the original order correct?
5. **Stop all consumers, fire ten orders, then start one again.** Where do the orders go in the meantime, and what happens when the consumer comes back?

---

*Questions? Leave a comment on the video — I read all of them.*

**hosiyar.com**
