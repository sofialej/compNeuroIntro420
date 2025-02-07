#lang scribble/book

@(require plot/pict 
	  scribble/base
	  scribble-math/dollar
	  scribble/example
          symalg)

@(define plot-eval
  (let ([eval  (make-base-eval)])
    (eval '(begin
             (require racket/math
                      racket/match
                      racket/list
                      racket/draw
                      racket/class
                      plot/pict
                      plot/utils)))
    eval))

@title{Differential Equations and Spiking Neuron Models}

@section[#:tag "Spiking Neuron Models"]{Goals}

Why are Differential Equations an important technique for computational modelling in psychology and neuroscience?

Work on the modeling of the action potential eventually resulted in @hyperlink["https://www.nobelprize.org/prizes/medicine/1963/summary/"]{Nobel Prizes}. The Hodgkin-Huxley equations that resulted from this work are differential equations. Subsequent models, even very marked simplifications such as the Integrate and Fire model, are also differential equations. When you rely on a simulation software that allows you to create populations of such neurons you are using, at least indirectly, a differential equation. It is worth knowing what they are.

Beyond that, the idea of a differential equation is a very intuitive and useful notion. You can recast the example of the @(secref "forgetting") forgetting curve as a differential equation in which the change in the strength of a memory over time is proportional to the current strength of the memory  as a function of time. @margin-note{Exponentials show up a lot in neuroscience and psychology. When you see a rate of change in a quantity that is proportional to the magnitude of that quantity there is an exponential hidden in there somewhere.}

Further, modern computers and their powers mean that we can often use differential equations in our models by naively implementing their effects as a series of very tiny steps. We might gain insight if we knew more about how to solve differential equations analytically, but often, if our goals our practical, that is running a simulation to see the result, we can be ignorant of differential equations at that level, and just deploy them as another practical tool. Just like you can now use software to implement Monte Carlo simulations in statistics without knowing the full details of the theory mathematically.

This gives us the following goals for this section:

@itemlist[#:style 'ordered @item{Learn what a Differential Equation is as a mathematical entity,}
          @item{Get an intuition for differential equations by thinking of them as slopes,}
          @item{Learn how they emerge as a natural effort to account for changing quantities in neuroscience and psychology,}
          @item{Put this altogether by writing programs to implement the integrate and fire point neuron model and a version of the Hodgkin-Huxley neuron model.}]
      
@margin-note{In preparation for things to come you might try to remember (or look up) what is the integral of one over x? In symbols, what is @($ "\\int \\frac{1}{x}~ dx")?}
@section{The Action Potential - a very short review}

Our goal is to use differential equations in code written to simulate spiking neurons. Therefore, we ought to remind ourselves about the basics of what is a neuronal action potential.

Give yourself 10 minutes to brush up on what an action potential is. First, try and draw an action potential:
@itemlist[@item{What are the axes?}
               @item{What ion causes the upward deflection?}
               @item{What causes the repolarization?}
               @item{Who discovered the action potential?}
               @item{Who won the Nobel Prize for characterizing the ionic events of the action potential experimentally and building a mathematical model?}]

Did you draw     @hyperlink["https://commons.wikimedia.org/w/index.php?curid=44114666"]{this}?

@bold{An aside: Notation}

Mathematics is full of notation. And one person's notation is another person's jargon. The key thing is not to let yourself be scared off. Often the motivation for mathematical notation is just convenience: condensing something that would take a long time to say or write into an abbreviated form. It is the equivalent of saying "meh" or "lol".  Mathematical notation is just a technical emoji. You probably know the mathematical idea that is being represented; you just don't know the abbreviation that is being used. So, just like you can teach granma the meaning of TMI you can with a little bit of practice get used to the Greek symbols that appear so often in mathematical presentations. 

As a first exercise, write out in long hand what is meant by the
following:

@(use-mathjax)

@($$ "\\sum_{\\forall x \\in \\left\\{ 1 , 2 , 3 \\right \\}} x ~=~ 6")
Did you write: @hyperlink["../sections/notation-answer.txt"]{this?}


@subsection{Multiple Ways to Say the Same Thing}

Another thing to note about mathematical notation is that it often provides more than one way to say the same thing. Which notation is used depends on context and the technical community the work is intended for. Computer scientists frequently use @tt{i} as a variable for indexing a loop. To the mathematician it is the complex part of an imaginary number @($ "i~=~\\sqrt{-1}"), but engineers use @tt{j} instead. Here are some of the many different ways you may see the derivative depicted.

Leibniz notation: @($ "\\frac{dx}{dt}")

Physicists often use this for derivatives with respect to time (@tt{t}): @($ "\\dot{x}")

Mathematicians often use the variable itself as a representation for the function and use the number of "primes" to indicate how many derivatives to take: @($ "x'")

Or they may make the variable representing the function explicit if they think that will make their reasoning clearer in the present context: @($ "f'(x)")

This is called operator notation. You won't see it as much, but when doing certain kinds of proofs or reasoning more abstractly it can be much more convenient: @($ "D~f") 


@section{Derivatives are Slopes}

There may be many ways to write out the notation for a derivative, but the uniting concept behind them is as "rates of change." They are essentially just the slopes you learned about in secondary school. The old "rise over run" where the length of the run is made very, very small.

You might want to pause here and make sure you remember what a slope is. 

@itemlist[@item{Can you write the equation to find the slope of a line?}
               @item{How would you apply this to a curve and not a line?}
               @item{When in doubt return to definition. What is the definition of a slope of a function?}]
We will see momentarily how to go from our basic understanding of the slope of a line to @bold{generalize} it to also include curves. This notion of generalizing is often a key step in developing an idea for modeling. 


@subsection{Use your computer as a tool for exploration}

Demonstrating something mathematically can give a great deal of satisfaction and ultimately is the guarantor of whether something is correct. Often we want to know more than whether something is correct in the abstract, we want to see specific examples. Sometimes pencil and paper are the best approach, but often we can do the same thing more quickly and more extensively by using our computer. Let's digress to use our computer for visualizing ideas about slopes. You should try to get these to work in Dr. Racket. 

@examples[#:eval plot-eval
          (begin
            (define xs (list 1 2 3 4 5))
            (define ys (list 2 4 6 8 10))
            (plot (lines (map vector xs ys)) #:title "A Line: What is it's slope?"))]




@examples[#:eval plot-eval
          (plot (list (function (lambda (x) (expt x 3)) (- 3) 3)
                      (function (lambda (x) (- (* 12 x) 16)) 1 3)) #:title "A curve (of what?) showing the slope at a point.")]


@(plot (list (function (lambda (x) (expt x 3)) 1.5 2.5)
             (function (lambda (x) (- (* 12 x) 16)) 1.5 2.5)) #:title "An enlarged view of the same function.")



@margin-note{Derivatives are Instantaneous Slopes}

These plots are intended to demonstrate the idea that locally everything is linear. If you calculate the slope for your curve exactly like you do for a line you will get something that starts to look more and more like a line the smaller your "run" gets. The idea is that you pick two points that are "close enough" and your derivative becomes "close enough." At least with a computer. Mathematically, you just keep going to the limit.

@elemtag{derivative}
@bold{Definition of the Derivative}
@$$["\\frac{df}{dx} = \\lim_{h \\to 0}\\frac{f(x + h) - f(x)}{(x + h) - x}"]{\tag{D}}
@(linebreak)

@section[#:tag "use-deriv-to-solve"]{Using Derivatives to Solve Problems With a Computer}

@subsection{What is the square root of 128?}

We want to know the value of @($ "x") that makes @($ "128 =x^2") true?

@margin-note*{Always use the computer for the busy work when you can. Your computer can solve many mathematical problems for you. For example, requiring @tt{symalg} we can programatically find that the derivative of @($ "x^2") is 
@($ (latex (simplify (differentiate (parse-infix "x^2"))))). Look at the code for this @tt{margin-note} and you will see how I computed that with racket (and then typeset it).}

@itemlist[@item{Come up with a guess.}
               @item{Calculate the error.}
               @item{Adjust your guess based on the error.}
               @item{This adjustment will use the derivative.}]


@subsubsection{Working Through an Example}

Let's say we want to solve for @($ "x") when @($ "x^2 = 128"). How might we start? When in doubt, guess! 

How much is your guess off?

@($$ "\\mbox{Error} = \\mbox{(my guess)}^2 - \\mbox{128}")

What we want to do now is adjust our guess. Since we know how much our function changes its output for each adjustment in the input, @margin-note*{How do we know this? Our derivative is a @italic{rate of change}.} we can revise our guess based on this necessary adjustment. If we are still wrong, we just repeat the process. 

To get there let us consider representing the ratio of how our function's output changes for changes in input. We can just make things concrete. 

@($$ "\\frac{\\Delta~\\mbox{output}}{\\Delta~\\mbox{input}} = \\frac{\\mbox{function(input_1)} - \\mbox{function(input_0)}}{\\mbox{input_1} - \\mbox{input_0}}")

If you take a look at the definition of the derivative @elemref["derivative"]{(equation D)} above you will see the resemblance, except for the absence of the limit. When trying to solve this problem we don't initially know both inputs, but we do know that when we put in the solution to our problem we will get 128. And we also know that we can compute the derivative. A bit of rearranging and renaming give us.@margin-note*{Can you map the steps I took to get this equation from the one above?}

The equation of a frictionless spring is:

@elemtag{spring}
@$$["\\frac{d^2 s}{dt^2} = -P~s"]{\tag{S}}
@(linebreak)

where 's' refers to space, 't' refers to time, and 'P' is a constant, often called the spring constant, that indicates how stiff or springy the spring is. 


Imagine that we knew this derivative. It would tell us how much space the spring head would move for a given, very small, increment of time. We could then just add this to our current position to get the new position and repeat. This method of using a derivative to iterate forward is sometimes called the Euler method.

Returning to our definition of the derivative:

@($$"\\frac{s(t + \\Delta t) - s(t)}{\\Delta t} = velocity \\approx \\frac{d s}{d t}")

But our spring equation is not given in terms of the velocity it is given in terms of the acceleration which is the second derivative. Therefore, to find our new position we need the velocity, but we only have the acceleration. However, if we knew the acceleration and the velocity we could use that to calculate the new velocity. Unfortunately we don't know the velocity, unless ... , maybe we could just assume something. Let's say it is zero because we have started our process where we have stretched the spring, and are holding it, just before letting it go. 

How will our velocity change with time?

@($$ "\\frac{v(t + \\Delta t) - v(t)}{\\Delta t} = acceleration \\approx \\frac{d v}{d t} = \\frac{d^2 s}{d t^2}")

 And we have a formula for this. We can now bootstrap our simulation.

Note the similiarity of the two functions. You could write a helper function that was generic to this pattern of old value + rate of change times the  time step, and just used the pertinent values. 

How do we know the formula for acceleration? We were given it in @elemref["spring"]{Equation S} above. 


@examples[#:eval plot-eval
          (require "./code/spring.rkt")
          (begin
            (define spring-results (release-spring ))
            (plot (lines (map vector (map fourth spring-results) (map third spring-results)))))]


@subsection{Damped Oscillators}

Provide the code for the damped oscillator. It has the formula of

@($$ "\\frac{d^2 s}{dt^2} = -P~s(t) - k~v(t)")

This should really only need to change a couple of lines to update the model to be able to handle the damped version as well. You might want to edit @hyperlink["./../code/spring.rkt"]{spring.rkt}.


