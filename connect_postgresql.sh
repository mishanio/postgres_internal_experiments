#!/bin/bash

PGPASSWORD=postgres_password psql -U postgres_user -h localhost -p 5431 experiments
