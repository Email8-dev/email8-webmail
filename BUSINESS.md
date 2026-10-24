# Email8:Webmail - Business Requirements & Functionality

> Audience: product owners, business analysts, and anyone evaluating what
> Email8:Webmail **does for the business**. For architecture read `README.md`;
> for wire-level detail read `DESIGN.md`.

## 1. Business Purpose

Email8:Webmail is the **browser mail client** of the Email product line.
It delivers:

- **Mail anywhere, instantly** - a user with nothing installed but a
  browser reads, searches, files, and composes mail from the same
  mailbox their desktop clients use.
- **The modern-protocol showcase** - Webmail is a JMAP client: fast
  folder trees, incremental sync, and immediate visibility of state
  changes, demonstrating the mail platform's native API contract.
- **Personal information management in one place** - calendar and
  contacts basics live next to the inbox, powered by the same
  account's groupware data.
- **Zero local secrets** - authentication rides the platform's BFF
  session flow; tokens and credentials never live in the browser.

## 2. Business Scope (What the Service Provides)

| # | Capability area | What the business gets |
|---|---|---|
| 1 | Sign-in & session | Platform sign-in via the shared BFF auth flow (session bootstrap, error/loading states) |
| 2 | Landing & shell | Post-login landing page and app shell with mail navigation |
| 3 | Mailbox browsing | Folder tree (INBOX, Trash, Junk, Drafts, Sent, Archive + user folders) via `Mailbox/get` |
| 4 | Message lists | Per-mailbox message lists via `Email/query` + `Email/get` |
| 5 | Reading | Message detail view (headers, body) |
| 6 | Composing & sending | Draft creation via JMAP then submission (`EmailSubmission` through the platform's MTA path) |
| 7 | Search | Mail search over account data (`Email/query` filters) |
| 8 | Calendar | Calendar event browsing via JMAP `CalendarEvent/get` |
| 9 | Contacts | Contact basics via JMAP `ContactCard/get` |
| 10 | App registration | Published as a public platform app (`email8-webmail`) with a DCR-created OAuth client |
| 11 | Theming | Shared platform design tokens (single `theme.dart` over the design system) |

**What the service does NOT own (business boundary):**

| Out of scope | Owned by |
|---|---|
| Any mail data | Email8:Store (Webmail is a stateless client) |
| Sending/queueing | Email8:Mta (via Store's submission handoff) |
| Session issuing, identity | Sentin8:Auth (Webmail consumes the shared auth provider) |
| Token handling / proxying | Sentin8:BFF (tokens live server-side, never in the client) |
| Hosting the app bundle | Sentin8:App / platform web hosting (`build/web` served) |
| Push notifications / SSE | Currently not consumed by Webmail (JMAP polling/refresh UX) |
| Sieve / protocol clients | Email8:Access |

## 3. Business Capabilities

### 3.1 Mail experience

| Capability | Business rule |
|---|---|
| Folder tree | The mailbox list renders the account's mailboxes with unread/state awareness from `Mailbox/get` |
| Message flow | `Email/query` pages a mailbox's messages; opening one fetches full content (`Email/get`) |
| Compose | New drafts are created through JMAP; submission enqueues through the platform mail pipeline - sent mail is the user's normal flow, indistinguishable from a desktop client's send |
| Search | Query filters operate server-side (indexed full-text/keywords in Store) - no client-side scan of all mail |
| Threads & state | State strings from JMAP keep views consistent with Server truth; refetches are incremental |

### 3.2 Groupware basics

| Capability | Business rule |
|---|---|
| Calendar | Events render from the user's default calendar collection |
| Contacts | Contact cards (names, emails) render from the user's address book |
| Boundary | Calendar/contact editing is out of the current client scope (read basics); protocol support exists server-side |

### 3.3 Identity & security

| Capability | Business rule |
|---|---|
| BFF-only auth | The app calls `/proxy/email8-store/*` through Sentin8:BFF; access tokens never reach browser storage |
| OAuth profile | Public app (`visibility: public`), authorization_code + refresh_token grants, PKCE-style `code` response, `token_endpoint_auth_method: none` (no client secret), scopes limited to mail + groupware + storage needs, no forced consent prompt |
| DCR registration | `supports_dcr: true` - the client registers dynamically at enroll time; no hardcoded shared secret |
| Session lifecycle | Login state, loading, and bootstrap failures are handled by the shared platform auth runtime (re-used, not re-invented) |

### 3.4 Runtime and packaging

| Capability | Business rule |
|---|---|
| Runtime context | App bootfetches platform runtime context (BFF base URL, tenant branding) through the shared Flutter package |
| Versioned builds | `make build` stamps the web bundle with the repo build hash; the app `.env` ships inside `build/web` |
| Dev loop | `make start` guarantees dev infra + trimmed backend boot (acme/auth/proxy/bus/sys/bff/web) then serves Flutter web on port 3200 |

## 4. Business Events (Outbound)

Webmail emits **no platform events** - it is a pure client. It
consumes server events indirectly (JMAP state refreshing on API
responses).

| Channel | Content |
|---|---|
| Telemetry | None of its own; the platform app-hosting surface tracks app usage |

**Inbound (consumed as data, not as a consumer):**

| Surface | Used for |
|---|---|
| JMAP responses | Rendering mailbox/message/identity state |
| BFF session state | Sign-in gating |

## 5. Business Rules & Invariants

1. **No token ever touches the browser** - authentication always runs
   through BFF; the web client cannot hold, refresh, or leak access
   tokens.
2. **No direct backend calls** - every API call goes to
   `/proxy/email8-store/{...}`; the app has no Store/MTA endpoints
   wired.
3. **One shared client stack** - auth provider, runtime bootstrap,
   theming, and API client all come from the shared `sentin8` Flutter
   package; the app contributes only mail pages.
4. **All data is server-derived** - the app holds no local mailbox
   cache of record; refreshes re-query JMAP (client state is
   presentation-only).
5. **Scope-limited client** - requested OAuth scopes cover only mail
   read/write, groupware read/write, and the storage scopes needed for
   attachments; no admin scopes exist in this client.
6. **Public but gated** - the listing is public, but data access still
   requires a valid platform session with matching scopes.

## 6. Target-User Roles & Use Cases

| Persona | What they do with Email8:Webmail |
|---|---|
| End users | Read, search, file, and send mail from a browser; no client install |
| Traveling users | Access mail from any device that can run a browser |
| New users | Get a working mail UI for their freshly provisioned account before configuring desktop clients |
| Calendar/contact users | Glance at events and contacts without leaving mail |
| Product evaluators | See the JMAP-based modern mail experience as a reference implementation |
| Platform operators | Serve the app as a registered platform app with scoped OAuth defaults |

## 7. KPIs / Success Criteria

| Category | Target |
|---|---|
| Usability | Mailbox open → message list → read → reply flow works without training |
| Consistency | What a desktop client sees, Webmail sees (same Store-backed truth) |
| Security | Zero tokens in client storage; zero direct-service calls; DCR-registered client |
| Performance | JMAP batching keeps interactions snappy; lists use server-side query paging |
| Maintainability | No duplicated theme/auth/bootstrap code - all shared package re-exports |
| Reliability | Bootstrap failures render guidance (error/loading pages) rather than white screens |

## 8. Dependencies & Reliance on Other Services

| Relied on | For |
|---|---|
| Sentin8:BFF | Session auth + `/proxy/email8-store` JMAP forwarding |
| Email8:Store | All mail/groupware data (via JMAP) |
| Email8:Mta | Send path (transitively via Store submission handoff) |
| Sentin8:Auth | Sign-in, OAuth client (DCR), scopes |
| Sentin8:App / web hosting | Bundle serving + app listing (`email8-webmail`) |
| Sentin8:Flutter package | Auth provider, runtime bootstrap, theme, API client (path dependency `../../sentin8/sentin8-flutter`) |

## 9. Acceptance Criteria

1. A user signs in through the platform flow and lands in the mail
   shell without the app ever seeing a token.
2. Folder tree, message lists, message detail, compose/send, search,
   calendar, and contacts pages all render data through
   `/proxy/email8-store/jmap`.
3. A sent message appears in the user's Sent folder and is queued by
   the platform's submission pipeline.
4. The app requests only its declared scopes and is registered as a
   public DCR client (`service-registration.json`).
5. `make build` produces a versioned web bundle; `make start` boots
   backend deps + dev server; `make check` (analyze + tests) passes.
6. Bootstrap failure paths (missing env, unreachable BFF) render the
   shared error/loading pages.

## 10. Open Business Questions

- Real-time push in the client (SSE/WebSocket) versus current refresh
  UX.
- Vacation response management in the client (server shape exists).
- Rich calendar/contact editing UX.
- Mobile/native packaging (Flutter web today; the shared SDK keeps
  native feasible).

---

**Architecture & Design:** email8:webmail and its underlying concepts were designed by [Hamid Jahanzad](https://www.linkedin.com/in/hamidjahanzad/).