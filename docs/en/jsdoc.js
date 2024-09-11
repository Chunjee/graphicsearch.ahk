/**
 * Finds GraphicSearch queries on the screen.
 * @method search
 * @memberof graphicsearch
 * @param {string} graphicsearch_query - The GraphicSearch query(s) to search. Must be concatenated with `|` if searching multiple graphics.
 * @param {Object} [options={}] - The options object.
 * @param {number} [options.x1=0] - The search scope's upper left corner x-coordinate.
 * @param {number} [options.y1=0] - The search scope's upper left corner y-coordinate.
 * @param {number} [options.x2=A_ScreenWidth] - The search scope's lower right corner x-coordinate.
 * @param {number} [options.y2=A_ScreenHeight] - The search scope's lower right corner y-coordinate.
 * @param {number} [options.err1=1] - Fault tolerance of graphic (0.1=10%).
 * @param {number} [options.err0=0] - Fault tolerance of background (0.1=10%).
 * @param {boolean} [options.screenshot=1] - Whether or not to capture a new screenshot. If the value is 0, the last captured screenshot will be used.
 * @param {boolean} [options.findall=1] - Whether or not to find all instances or just one.
 * @param {boolean} [options.joinqueries=1] - Join all GraphicSearch queries for combination lookup.
 * @param {number} [options.offsetx=1] - The max x offset for combination lookup.
 * @param {number} [options.offsety=0] - The max y offset for combination lookup.
 * @returns {Array<Object>|false} Returns an array of objects containing all lookup results, or `false` if no matches were found.
 * 
 * @example
 * // Define the options object
 * const optionsObj = {
 *   x1: 0,
 *   y1: 0,
 *   x2: A_ScreenWidth,
 *   y2: A_ScreenHeight,
 *   err1: 0,
 *   err0: 0,
 *   screenshot: 1,
 *   findall: 1,
 *   joinqueries: 1,
 *   offsetx: 1,
 *   offsety: 1
 * };
 *
 * // Perform a search with the defined options
 * oGraphicSearch.search("|<tag>*165$22.03z", optionsObj);
 *
 * // Perform a search with specific scope coordinates
 * oGraphicSearch.search("|<tag>*165$22.03z", {x2: 100, y2: 100});
 */
