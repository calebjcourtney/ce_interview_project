## Introduction
The purpose of this project is to test an applicant's coding and software design abilities. To that end, you may use online documentation and resources just as you would in your day-to-day work. This project is designed to be completed within a few hours.

## Project Story

The customer occasionally remembers a few words from a poem they once memorized.  When this happens they'd like help identifying the exact line that they are distantly recalling.  Included in this repository is [lepanto.txt](lepanto.txt), the text of a poem by G.K. Chesterton.  Your task is to write a program that prompts the user to enter the words they remember, then prints the line of the poem which you believe is the most likely match.

Here's what a hypothetical session might look like:

```
$ ./my_solution
>his head a flag
Holding his head up for a flag of all the free.
```

How you implement the "match" model is up to you but be prepared to justify the choices you make.  Assume the user doesn't have perfect recall and will confuse words from different lines on occasion.

## Build
This project was built using [DUB](https://code.dlang.org/). Simply running `dub build` should produce the executable. However, there are no dependencies, so you can also run `dmd source/app.d`, and this will produce an `app` executable file. In the examples below, I assume the process is built using DUB, so the name of the executable is `ce_interview_project`.

## Running
As was described in the required documentation, this expects an input from stdin, however I also added the ability to just pass the words in via args at initial input.

For example,

```
./ce_interview_project
>his head a flag
```

Can simply be run with:

```
./ce_interview_project his head a flag
```

They result in the same output.

## Implementation
A simple, log-based TF-IDF algorithm was used in this implementation. TF-IDF was used because it helps value words with a higher uniqueness, which seems to fit the project use-case. Given that the user might not have perfect recall and some words might get mixed up, TF-IDF lends more value to the distinctive words being more indicative of which line this is happening on.

So in the instance of "his head a flag" (example from the given project), we get a good value on "flag", since it is only used once in the poem. The same goes for "head", also only used on the given line.

At the same time, "his" is used 29 times, while "a" is used 26 times. Given how common these two words are, they should not be valued as highly as the other less common words for determining which line in the poem we get back.

### Process

There are two different sections: (1) the corpus and document building section and (2) the matching section.
Ideally the first would be processed once, up front and probably loaded into a sqlite database for quick access of the data. Given the size of this poem though, it's not really a problem to run this each time.

1. Corpus and document building:
	- iterates through each line of the poem
    - cleans the line, counts the percent of times a word is used in the line as a proxy for line importance
    - for each unique word found in the document (line), makes record of that word in the corpus
    - finally, convert the words of the corpus into a proxy for their importance by taking the log10 of (the total number of records divided by the number of records that word is found in
2. Matching from the input text
    - we use the same process as above to clean the input string
    - multiply the unique words from the input by the corpus importance from step 1.4
    - map each unique word to each line it is found in the corpus
    - each line in the corpus (if it has a corresponding word) receives a relevance score for the word relevance * corpus importance * input importance


This process actually has the added benefit of being able to weight certain input words as being more important than others.
For example, `./ce_interview_project his head a flag` results in a score of ~`0.66`
`./ce_interview_project his head head head a flag flag flag` results in a score of ~`0.54`


### Improvements to the Process
The first thing that comes to mind is support for UTF-8 characters. The function `cleanSplitText` removes anything that is non-ascii, replacing it with a space. So in the line: `They veil the plumèd lions on the galleys of St. Mark;`, `plumèd` turnes into `["plum", "d"]`. So if you do a search for `plumèd`, it will give you the correct result, but if you look for `plumed`, then it would give you an incorrect result (`no match`).

This is why I think deeper support for UTF-8 characters would be helpful, depending on how much of a priority it should be.

Another area for improvement would be improving the scoring factor. I think it would be good to have something along the lines of a probability that the output is correct.
