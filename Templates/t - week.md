---
date_creation: <% tp.file.creation_date("YYYY-MM-DD") %>
time_creation: <% tp.file.creation_date("HH:mm:SS") %>
tags:
  - weeklynotes
---
- prev wr:: <% `[[w-${moment().format("YYYY")}-W${moment().subtract(1, 'weeks').format("ww")}]]` %>
- (delete these two after you've completed 💙 )
- make a new week note: [[week review checklist]]
- projects:: [[gtd - projects]]
	- take things from projects and put them here. execute
	- each day, look at stuff from this file to find what to work on.
- go back and review previous week

## - what is the project for this week?
- What's the single focus?
	- (note: this has given me feelings of direction. "what would make me feel cool this week?")
- [[mission - moc]]
	- (delete this at the ned of week, so not crazy amount of links everywhere)

##  - what am I doing this week?
- [ ] <% tp.file.cursor() %>

## - who do I want to hang out with?
- [ ] call Grandma

## - reflection
- 