# creating employee database to be used by lambda function
import sqlite3
import random
from datetime import date, timedelta

# Connect to the SQLite database (creates a new one if it doesn't exist)
conn = sqlite3.connect('employee_database.db')
c = conn.cursor()

# Create the employees table
c.execute('''CREATE TABLE IF NOT EXISTS employees
                (employee_id INTEGER PRIMARY KEY AUTOINCREMENT, employee_name TEXT, employee_job_title TEXT, employee_start_date TEXT, employee_employment_status TEXT)''')

# Create the vacations table
c.execute('''CREATE TABLE IF NOT EXISTS vacations
                (employee_id INTEGER, year INTEGER, employee_total_vacation_days INTEGER, employee_vacation_days_taken INTEGER, employee_vacation_days_available INTEGER, FOREIGN KEY(employee_id) REFERENCES employees(employee_id))''')

# Create the planned_vacations table
c.execute('''CREATE TABLE IF NOT EXISTS planned_vacations
                (employee_id INTEGER, vacation_start_date TEXT, vacation_end_date TEXT, vacation_days_taken INTEGER, FOREIGN KEY(employee_id) REFERENCES employees(employee_id))''')

# Generate some random data for 10 employees
employee_names = ['John Doe', 'Jane Smith', 'Bob Johnson', 'Alice Williams', 'Tom Brown', 'Emily Davis', 'Michael Wilson', 'Sarah Taylor', 'David Anderson', 'Jessica Thompson']
job_titles = ['Manager', 'Developer', 'Designer', 'Analyst', 'Accountant', 'Sales Representative']
employment_statuses = ['Active', 'Inactive']

for i in range(10):
    name = employee_names[i]
    job_title = random.choice(job_titles)
    start_date = date(2015 + random.randint(0, 7), random.randint(1, 12), random.randint(1, 28)).strftime('%Y-%m-%d')
    employment_status = random.choice(employment_statuses)
    c.execute("INSERT INTO employees (employee_name, employee_job_title, employee_start_date, employee_employment_status) VALUES (?, ?, ?, ?)", (name, job_title, start_date, employment_status))
    employee_id = c.lastrowid

    # Generate vacation data for the current employee
    for year in range(date.today().year, date.today().year - 3, -1):
        total_vacation_days = random.randint(10, 30)
        days_taken = random.randint(0, total_vacation_days)
        days_available = total_vacation_days - days_taken
        c.execute("INSERT INTO vacations (employee_id, year, employee_total_vacation_days, employee_vacation_days_taken, employee_vacation_days_available) VALUES (?, ?, ?, ?, ?)", (employee_id, year, total_vacation_days, days_taken, days_available))

        # Generate some planned vacations for the current employee and year
        num_planned_vacations = random.randint(0, 3)
        for _ in range(num_planned_vacations):
            start_date = date(year, random.randint(1, 12), random.randint(1, 28)).strftime('%Y-%m-%d')
            end_date = (date(int(start_date[:4]), int(start_date[5:7]), int(start_date[8:])) + timedelta(days=random.randint(1, 14))).strftime('%Y-%m-%d')
            days_taken = (date(int(end_date[:4]), int(end_date[5:7]), int(end_date[8:])) - date(int(start_date[:4]), int(start_date[5:7]), int(start_date[8:])))
            c.execute("INSERT INTO planned_vacations (employee_id, vacation_start_date, vacation_end_date, vacation_days_taken) VALUES (?, ?, ?, ?)", (employee_id, start_date, end_date, days_taken.days))

# Commit the changes and close the connection
conn.commit()
conn.close()