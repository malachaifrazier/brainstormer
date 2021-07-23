# Brainstormer

Brainstormer is a fun tool that helps people come up with ideas together remotely. 

It is created with the intention to make it easier for facilitators to facilitate brainstorms. I've tried to achieve that by:

* keeping a low barrier of entry for participants - there's no signup needed, and participants get descriptions of what to do at every step
* Making the whole process tailored, so that you as a facilitator doesn't have to come up with how to do the brainstorm, but you can focus on the problem you want solved
* giving the whole experience a light and fun feel, since I believe that state of mind produces better ideas

You can try out Brainstomer online at brainstormer.online

## Open source

The source code of Brainstormer is open source under [the GNU General Public License v3.0](https://choosealicense.com/licenses/gpl-3.0/#)

That means that you can fork this project and use it however you wish, as long as you make any modifications to this source code available as open source under the same license.

## Setup

The project is using ruby on rails and tailwind. That means that you will need to have rails and ruby installed on your machine. 

You need to make sure that you have the correct versions of ruby and rails. 

clone the project and set up the database with:

``rails db:setup``

Install js dependencies

``npm install``

Install redis

Follow instructions [here](https://redis.io/topics/quickstart)

To install foreman, run:

``gem install foreman``

To run server, redis and webpacker locally, run: 

``foreman start -f Procfile.dev``

## How to contribute?

Thank you for reaching this far in the readme. You are already awesome!

Read more about how to contribute here: https://github.com/LoneKP/brainstormer.online/blob/main/CONTRIBUTING.md
