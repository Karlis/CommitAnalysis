# Tool usage

    - create graph and perform measurements.
    - extend graph with labels
    - perform analysis in R

# Setup
    - Clone git repositories of projects to analyze
    - Populate /data/projects.json with information about the projects
        - project directory
        - analysis start and end commit hash
        - module if you want to analyze just a specific subfoler of the project
        - regression line coefficiens

    - Download eclipse 3.6 (version is important)
    - Follow http://www.sable.mcgill.ca/ppa/ppa_eclipse.html to setup PPA for Eclipse


# Usage

    - Perform measurements
        - bugfix.rb
        - churn.rb
        - timestamp.rb
        - retrieve a list of bug inducing commits and save in /data/{project}/inducing.json

    - Create graph with graphs.rb

    - Perform architecture analysis

    - Extend the graph with labels using labels.rb
        - Data about the histories of each commit is saved /data/{project}/data.cvs



