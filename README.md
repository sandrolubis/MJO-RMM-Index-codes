\documentclass{article}
\usepackage{amsmath}
\usepackage{parskip}

\begin{document}

\section*{Instructions}

\textbf{Step 1:} \\
Running \texttt{Prepare\_needed\_vars\_for\_RMM.ncl} $\rightarrow$ Fill Missing Values in the data. Before running this, make a directory \texttt{input} first.

\vspace{0.5cm}

\textbf{Step 2:} \\
Running \texttt{get\_anom\_HighResMIP.ncl} $\rightarrow$ calculate anomalies (remove first three harmonics). Before running this, make a directory \texttt{anom} first.

\vspace{0.5cm}

\textbf{Step 3:} \\
Running \texttt{get\_RMM\_HighResMIP.ncl} $\rightarrow$ calculate RMM index based on observed EOF pattern from OBS. Before running this, make a directory \texttt{final\_output} first.

\vspace{0.5cm}

\textbf{Step 4:} \\
Go to the directory \texttt{final\_output} and then run the Python code \texttt{read\_PC1\_PC2.py}.

\end{document}
