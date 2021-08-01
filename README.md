# Normalizing-and-Analyzing-Covid-19-Data-with-SQL✨✨

The purpose of this project is to analyze Covid-19 situation worldwide. Data for this project is taken from [OurWordlInData](https://ourworldindata.org/covid-deaths).🎇

After downloading the data, I imported it into pgAdmin for analysis. Upon running simple queries on my main table, I noticed that there were a lot of repeating strings in the columns. Repeating strings increases the size occupied by the data, and slowers the processes of the database.🎡

Next up, I normalizaed the database by creating tables for location, iso_code and continent and linked it to the main my main table. This way, I was able to get rid of repeating strings in my database. 📅

The queries.sql file contains all the SQL queries for this project.

This SQL client used is PostgreSQL.🐘

### The database follows the schema in the image below.

![Untitled Workspace](https://user-images.githubusercontent.com/66962188/127756584-6e847ab6-1360-485a-9ca6-abe7ed8f1f88.jpg)

### Visualization with Tableau
The final visualization created with Tableau is below:

![Covid Dashboard](https://user-images.githubusercontent.com/66962188/127774443-04821106-74cd-47b0-b8a8-edd205f246a1.png)
