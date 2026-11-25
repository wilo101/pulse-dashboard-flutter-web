# Changelog

## 2.0.0
- Four screens with a navigation rail (wide) or bottom bar (narrow): Overview, Orders, Customers, Settings.
- Orders: server-side paging, debounced search, status filter chips, sortable columns, multi-select with bulk status change, CSV copy, order detail with items and status timeline.
- Customers: infinite scroll, tag filter, sort by spend or orders, add customer form with validation, customer detail with lifetime value and orders.
- Overview: range switch (7, 14, 30 days), trend versus the previous window, status and top customer breakdowns, pending-orders alert, AI summary that never blocks the numbers.
- Settings saved on the device: currency, compact numbers, dense tables, page size, alert threshold.
- Sign in screen, viewer (read-only) and admin roles, sample-data mode that follows the same rules as the server.
- State: one model per screen (Provider), a single API interface with two implementations (Relay over HTTP, in-memory sample data), optimistic status change with rollback.
- Tests: models, sample API, Relay client (mock HTTP), every state model, and widget tests.

## 1.0.0
- Single dashboard page with KPI cards, chart and searchable orders table.
