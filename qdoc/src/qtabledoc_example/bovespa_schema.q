// @table cqs_bbo
// @owner brunk
// @src rtdev feed journals at /path/to/feed/YYYY/MM/cqs_mdelta.*
// @desc Per-exchange best bid and offer details for listed underliers.
// @note Table is a merged view of redundant a-side and b-side (per-line) journal files.
// @seealso cqs_nbbo, cts_prints
// @col cqsID Stock ticker
// @col line Cqs line id
// @col seq Per-line sequence number
// @col exchangeTime Exchange time
// @col exch Exchange
// @col bp Bid price
// @col bs Bid size
// @col ap Ask price
// @col as Ask size
// @col qc Quote condition
// @col rcvTimeA A-side receive time. May be null
// @col rcvTimeB A-side receive time. May be null

t:([]c1:();c2:())
