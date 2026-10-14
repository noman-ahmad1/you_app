/**
 * Pakistan Standard Time helpers.
 *
 * Karachi (PKT) is a fixed UTC+5 with no DST, so a constant offset is safe and
 * keeps date keys and day-window boundaries stable. Pure — no Firebase — so it
 * ports unchanged to any other backend.
 */

const KARACHI_OFFSET_MS = 5 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * @param {number} n A non-negative integer.
 * @return {string} `n` zero-padded to two digits.
 */
function pad2(n) {
    return n < 10 ? `0${n}` : `${n}`;
}

/**
 * Karachi (PKT, fixed UTC+5, no DST) calendar-day key `YYYY-MM-DD` for `instant`.
 * Used so Dodo's daily cap resets at PKT midnight regardless of device timezone.
 * @param {Date} instant The instant to derive the day key for.
 * @return {string} The PKT date key.
 */
function pktDateKey(instant) {
    const shifted = new Date(instant.getTime() + KARACHI_OFFSET_MS);
    return `${shifted.getUTCFullYear()}-${pad2(shifted.getUTCMonth() + 1)}-${pad2(shifted.getUTCDate())}`;
}

/**
 * Karachi (PKT) calendar-MONTH key `YYYY-MM` for `instant`. Used so the free
 * community-thread cap resets at the start of each PKT month.
 * @param {Date} instant The instant to derive the month key for.
 * @return {string} The PKT month key.
 */
function pktMonthKey(instant) {
    const shifted = new Date(instant.getTime() + KARACHI_OFFSET_MS);
    return `${shifted.getUTCFullYear()}-${pad2(shifted.getUTCMonth() + 1)}`;
}

module.exports = {KARACHI_OFFSET_MS, DAY_MS, pad2, pktDateKey, pktMonthKey};
