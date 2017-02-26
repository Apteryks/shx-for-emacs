;;; shx-test -- for testing shx and shx-split.

;; Authors: Chris Rayner (dchrisrayner @ gmail)
;; Created: May 23 2011
;; Keywords: comint-mode, shell-mode
;; Git: https://github.com/riscy/shx-for-emacs

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; A handful of tests for shx.  Coverage isn't great yet.
;; To run on a comint session with shx active type :test

;;; Code:

(require 'shx)
(require 'shx-split)
(require 's)

(defun shx-cmd/test (_args)
  "(SAFE) Test shx.
In particular run every function with the prefix shx-test.
Example:
:test"
  (insert "Running test suite \n")
  (shx--asynch-funcall
   (lambda ()
     (dolist (test-function (all-completions "shx-test" obarray 'functionp))
       (funcall (intern test-function))))))

(defun shx-assert (comment val)
  "Describe test with COMMENT; test truth of VAL."
  (save-excursion
    (goto-char (point-max))
    (forward-line -1)
    (goto-char (point-at-eol))
    (if val
        (shx-insert 'font-lock-string-face "✔")
      (shx-insert 'error (format "\n✘ %s" comment)))))


;; tests!

(defun shx-test-shx ()
  "Test core shx functions."
  (shx-assert "Image height is a positive integer."
              (and (integerp shx-img-height) (> shx-img-height 0)))
  (shx-assert "Filename splitting works with apostrophes."
              (equal '("first file" "second file" "third")
                     (shx--parse-filenames "'first file' 'second file' 'third'"))))

(defun shx-test-filename-parsing ()
  "Test filename parsing."
  (shx-assert "Filename splitting works with mixed apostrophes."
              (equal '("first file" "secondfile")
                     (shx--parse-filenames "'first file' secondfile")))
  (shx-assert "Filename splitting works with escaped spaces."
              (equal '("first file" "secondfile")
                     (shx--parse-filenames "first\\ file secondfile")))
  (shx-assert "Filename splitting works with current directory specified."
              (equal '("~/././~/.spacemacs")
                     (shx--parse-filenames "~/././~/.spacemacs"))))

(defun shx-test-point-predicates ()
  "Test some predicate functions on the point."
  (shx-assert "Point on last line works at point-max."
              (save-excursion (goto-char (point-max))
                              (shx-point-on-input?)))
  (shx-assert "Point on last line works on last line and point-max."
              (save-excursion (goto-char (point-max)) (backward-char)
                              (not (shx-point-on-input?))))
  (shx-assert "Point on last line fails when not on last line."
              (not (save-excursion (goto-char (point-min))
                                   (shx-point-on-input?))))
  (goto-char (point-max)))

(defun shx-test-input-handling ()
  "Test shx's input handling."
  (goto-char (point-max))
  (insert "test")
  (shx-assert "Recent input is recognized."
              (string= "test" (shx--current-input)))
  (comint-kill-input)
  (forward-line -1)
  (shx-send-input-or-copy-line)
  (shx-assert "Test line is copied."
              (s-prefix? "Running test suite" (shx--current-input)))
  (comint-kill-input)
  (shx-assert "Blank input is recognized."
              (string= (shx--current-input) "")))

(defun shx-test-split ()
  "Test window splitting functions."
  (goto-char (point-max))
  (when (< (window-height) shx-split-min)
    (forward-line -1)
    (end-of-line)
    (shx-insert 'error "\nWarning: window too short to test shx-split"))
  (shx-assert "Create split."
              (let ((currpt (point)))
                (shx-scroll-up)
                (and shx-split-active
                     (eq currpt (point)))))
  (shx-assert "Maintain split."
              (let ((currpt (point)))
                (shx-scroll-home)
                (eq currpt (point))))
  (shx-assert "Destroy split."
              (let ((currpt (point)))
                (shx-scroll-end)
                (and (not shx-split-active)
                     (eq currpt (point)))))
  (shx-assert "Create and destroy with home/end."
              (let ((currpt (point)))
                (shx-scroll-home)
                (shx-scroll-end)
                (eq currpt (point))))
  (shx-assert "Create destroy with pgup/pgdn."
              (let ((currpt (point)))
                (shx-scroll-up) (shx-scroll-up)
                (shx-scroll-down) (shx-scroll-down) (shx-scroll-down)
                (eq currpt (point))))
  (shx-assert "Try to find nonexistent split."
              (null (shx-scroll-find-tail))))

(defun shx-test-shx-cat ()
  "Test the `shx-cat' command."
  (let ((concatenation (shx-cat "Test" 'font-lock-string-face "test")))
    (shx-assert "Concatenates the strings."
                (string= concatenation "Testtest"))
    (shx-assert "Propertizes the text."
                (equal (get-text-property 4 'font-lock-face concatenation)
                       'font-lock-string-face))))

(defun shx-test-timers ()
  "Test functions that use Emacs' built-in timer."
  (if (shx--get-timer-list)
      (shx-insert 'error "\nWarning: :stop all timers to run timing tests"))
  (shx-assert "The timer list starts empty." (not (shx--get-timer-list)))
  (shx--delay-input "10 sec" "stub command")
  (shx-assert "The timer list is not empty." (eq 1 (length (shx--get-timer-list))))
  (cancel-timer (car (shx--get-timer-list)))
  (shx-assert "The timer list is empty again." (not (shx--get-timer-list))))

(provide 'shx-test)
;;; shx-test ends here
