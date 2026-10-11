# Website

## Leaderboard widget

`leaderboard-widget.html` is a self-contained leaderboard box for the project website. It shows the top 10 scores from the leaderboard server and refreshes every 30 seconds, styled like the in-game leaderboard.

### Preview it
Double-click `leaderboard-widget.html` to open it in your browser. With no server set, it shows sample scores and a "Preview" note.

### Put it on the GoDaddy site
1. Open your site in GoDaddy's Website Builder and click **Edit Website**.
2. Add a section and pick **HTML** (it may be listed as **Embed code** or **Custom code**).
3. Open `leaderboard-widget.html` in a text editor, copy **everything**, and paste it into that section.
4. Save and **Publish**.

### Connect it to the real leaderboard
Near the bottom of the file, set `API_BASE` to the server's address. It's the same address as `BASE_URL` in the game (`morse-code-defense/leaderboard/leaderboard_api.gd`):

```js
var API_BASE = "https://example.com/api";
```

Then paste the updated code into GoDaddy again. The server must use HTTPS and allow the website to read scores (CORS); see the "The website" section of `morse-code-defense/leaderboard/API.md`.

To try a server without editing the file, open the widget with `?api=` at the end of its address, e.g. `leaderboard-widget.html?api=https://example.com/api`.

### If it says "Couldn't reach the leaderboard"
- The server is down or `API_BASE` is wrong, or
- the server isn't sending `Access-Control-Allow-Origin` (CORS), or
- the server address starts with `http://` instead of `https://`.
