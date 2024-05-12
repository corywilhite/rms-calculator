# RMS Calculator

Takes a folder of .wav files and calculates the Root Mean Square (RMS) information.
Outputs the RMS info to a .csv file

Example usage:

`swift /Path/to/rms_calculator.swift --path ~/Desktop/samples/ --output ~/Desktop/rms_sample_info.csv`

You can also modify the included `run` file to include these parameters. The `run` file is marked as executable and will automatically invoke the swift compiler. 

Example usage of the `run` file:

`/Path/to/run`

| Argument | Description |
| -------- | ----------- |
| --path | Expects the path to your folder of .wav samples |
| --output | Expects the exact file path for the output, including .csv that needs to be included in the file extension |
