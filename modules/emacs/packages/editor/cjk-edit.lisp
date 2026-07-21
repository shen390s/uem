(defun cjk-edit-entry (self action)
  (case action
    ((:INIT)
     #/
     (progn
       (defun uem/cjk-char-p (char)
         "Return non-nil if CHAR is a CJK character."
         (and char
              (string-match-p "\\cC\\|\\cK\\|\\cH"
                              (string char))))

       (defun uem/latin-char-p (char)
         "Return non-nil if CHAR is a Latin/ASCII character (letter or digit)."
         (and char
              (or (and (>= char ?a) (<= char ?z))
                  (and (>= char ?A) (<= char ?Z))
                  (and (>= char ?0) (<= char ?9))
                  (and (>= char ?À) (<= char ?ö))
                  (and (>= char ?ø) (<= char ?ÿ)))))

       (defun uem/join-paragraph-lines (beg end)
         "Join lines within each paragraph in the region.
Paragraphs are separated by empty lines.
Lines within the same paragraph are joined into a single line."
         (interactive "r")
         (save-excursion
           (save-restriction
             (narrow-to-region beg end)
             (goto-char (point-min))
             (while (not (eobp))
               ;; Skip empty lines
               (while (and (not (eobp))
                           (looking-at "^[[:space:]]*$"))
                 (forward-line 1))
               ;; Join non-empty lines within a paragraph
               (let ((para-start (point)))
                 (while (and (not (eobp))
                             (not (looking-at "^[[:space:]]*$")))
                   (forward-line 1))
                 ;; Now join lines in this paragraph
                 (when (> (point) para-start)
                   (goto-char para-start)
                   (end-of-line)
                   (while (and (< (point) (point-max))
                               (not (looking-at "\n[[:space:]]*$")))
                     (delete-char 1) ;; delete the newline
                     (unless (or (eobp)
                                 (looking-at "[[:space:]]*$"))
                       ;; no extra space inserted
                       )
                     (end-of-line))
                   (when (< (point) (point-max))
                     (forward-line 1))))))))

       (defun uem/delete-cjk-spaces (beg end)
         "Delete space characters between CJK and CJK, CJK and Latin, Latin and CJK in region."
         (interactive "r")
         (save-excursion
           (save-restriction
             (narrow-to-region beg end)
             (goto-char (point-min))
             (while (< (point) (point-max))
               (if (and (member (char-after) '(?\s ?\t))
                        ;; Check char before the space(s)
                        (let ((before-char (char-before)))
                          (and before-char
                               (or (uem/cjk-char-p before-char)
                                   (uem/latin-char-p before-char)))))
                   ;; Found space(s), check if we should delete
                   (let ((space-start (point))
                         (before-char (char-before)))
                     ;; Skip all spaces
                     (skip-chars-forward " \t")
                     (let ((after-char (char-after)))
                       (if (and after-char
                                (or
                                 ;; CJK <space> CJK
                                 (and (uem/cjk-char-p before-char)
                                      (uem/cjk-char-p after-char))
                                 ;; CJK <space> Latin
                                 (and (uem/cjk-char-p before-char)
                                      (uem/latin-char-p after-char))
                                 ;; Latin <space> CJK
                                 (and (uem/latin-char-p before-char)
                                      (uem/cjk-char-p after-char))))
                           ;; Delete the spaces
                           (delete-region space-start (point))
                         ;; Not a match, move past
                         nil)))
                 ;; Not a space, move forward
                 (forward-char 1)))))))
     /#)
    ((:CALL)
     #/
     (progn
       t)
     /#
     )))

(feat! cjk-edit
       "Commands for CJK text editing: join paragraph lines and delete CJK spaces"
       (:editor)
       cjk-edit-entry)
