(defun mark-word (&optional arg allow-extend)
  "Set mark ARG words away from point.
The place mark goes is the same place \\[forward-word] would
move to with the same argument.
Interactively, if this command is repeated
or (in Transient Mark mode) if the mark is active,
it marks the next ARG words after the ones already marked."
  (interactive "P\np")
  (cond
   ((and allow-extend
         (or (and (eq last-command this-command) (mark t)) (region-active-p)))
    (setq arg
          (if arg
              (prefix-numeric-value arg)
            (if (< (mark) (point))
                -1
              1)))
    (set-mark
     (save-excursion
       (goto-char (mark))
       (forward-word arg)
       (point))))
   (t
    (push-mark
     (save-excursion
       (forward-word (prefix-numeric-value arg))
       (point))
     nil t))))
