///usr/bin/true << //EOF
/*
 * ccnr/ccnr.c
 *
 * Main program of ccnr - the CCNx Repository Daemon
 *
 * Copyright (C) 2008-2011 Palo Alto Research Center, Inc.
 *
 * This work is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License version 2 as published by the
 * Free Software Foundation.
 * This work is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 * for more details. You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

/**
 * Main program of ccnr - the CCNx Daemon
 */

//EOF
///bin/sh -c 'for i in ccnr_dispatch.c ccnr_forwarding.c ccnr_init.c ccnr_io.c ccnr_link.c ccnr_match.c ccnr_net.c ccnr_sendq.c ccnr_store.c ccnr_util.c ; do echo "#include \"common.h\""  >$i; done'
///bin/cat << //EOF > common.h
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <netdb.h>
#include <poll.h>
#include <signal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <netinet/in.h>

#include <ccn/bloom.h>
#include <ccn/ccn.h>
#include <ccn/ccn_private.h>
#include <ccn/charbuf.h>
#include <ccn/face_mgmt.h>
#include <ccn/hashtb.h>
#include <ccn/indexbuf.h>
#include <ccn/schedule.h>
#include <ccn/reg_mgmt.h>
#include <ccn/uri.h>

#include "ccnr_private.h"

#define PUBLIC

PUBLIC struct ccn_charbuf *
r_util_charbuf_obtain(struct ccnr_handle * h);
PUBLIC void
r_util_charbuf_release(struct ccnr_handle * h, struct ccn_charbuf * c);
PUBLIC struct ccn_indexbuf *
r_util_indexbuf_obtain(struct ccnr_handle * h);
PUBLIC void
r_util_indexbuf_release(struct ccnr_handle * h, struct ccn_indexbuf * c);
PUBLIC struct fdholder *
r_io_fdholder_from_fd(struct ccnr_handle * h, unsigned filedesc);
PUBLIC int
r_io_enroll_face(struct ccnr_handle * h, struct fdholder * fdholder);
PUBLIC void
r_sendq_content_queue_destroy(struct ccnr_handle * h, struct content_queue ** pq);
PUBLIC struct content_entry *
r_store_content_from_accession(struct ccnr_handle * h, ccn_accession_t accession);
PUBLIC void
r_store_enroll_content(struct ccnr_handle * h, struct content_entry * content);
PUBLIC void
r_store_content_skiplist_insert(struct ccnr_handle * h, struct content_entry * content);
PUBLIC struct content_entry *
r_store_find_first_match_candidate(struct ccnr_handle * h,
						   const unsigned char *interest_msg,
						   const struct ccn_parsed_interest * pi);
PUBLIC int
r_store_content_matches_interest_prefix(struct ccnr_handle * h,
								struct content_entry * content,
								const unsigned char *interest_msg,
								struct ccn_indexbuf * comps,
								int prefix_comps);
PUBLIC          ccn_accession_t
r_store_content_skiplist_next(struct ccnr_handle * h, struct content_entry * content);
PUBLIC void
r_match_consume_interest(struct ccnr_handle * h, struct propagating_entry * pe);
PUBLIC void
r_fwd_finalize_nameprefix(struct hashtb_enumerator * e);
PUBLIC void
r_fwd_finalize_propagating(struct hashtb_enumerator * e);
PUBLIC struct fdholder *
r_io_record_connection(struct ccnr_handle * h, int fd,
				  struct sockaddr * who, socklen_t wholen,
				  int setflags);
PUBLIC int
r_io_accept_connection(struct ccnr_handle * h, int listener_fd);
PUBLIC void
r_io_shutdown_client_fd(struct ccnr_handle * h, int fd);
PUBLIC void
r_link_send_content(struct ccnr_handle * h, struct fdholder * fdholder, struct content_entry * content);
PUBLIC int
r_sendq_face_send_queue_insert(struct ccnr_handle * h,
					   struct fdholder * fdholder, struct content_entry * content);
PUBLIC int
r_match_consume_matching_interests(struct ccnr_handle * h,
						   struct nameprefix_entry * npe,
						   struct content_entry * content,
						   struct ccn_parsed_ContentObject * pc,
						   struct fdholder * fdholder);
PUBLIC void
r_fwd_adjust_npe_predicted_response(struct ccnr_handle * h,
							  struct nameprefix_entry * npe, int up);
PUBLIC int
r_match_match_interests(struct ccnr_handle * h, struct content_entry * content,
				struct ccn_parsed_ContentObject * pc,
				struct fdholder * fdholder, struct fdholder * from_face);
PUBLIC void
r_link_stuff_and_send(struct ccnr_handle * h, struct fdholder * fdholder,
			   const unsigned char *data1, size_t size1,
			   const unsigned char *data2, size_t size2);
PUBLIC void
r_link_ccn_link_state_init(struct ccnr_handle * h, struct fdholder * fdholder);
PUBLIC int
r_link_process_incoming_link_message(struct ccnr_handle * h,
							  struct fdholder * fdholder, enum ccn_dtag dtag,
							  unsigned char *msg, size_t size);
PUBLIC void
r_fwd_reap_needed(struct ccnr_handle * h, int init_delay_usec);
PUBLIC int
r_store_remove_content(struct ccnr_handle * h, struct content_entry * content);
PUBLIC void
r_fwd_age_forwarding_needed(struct ccnr_handle * h);
PUBLIC void
r_io_register_new_face(struct ccnr_handle * h, struct fdholder * fdholder);
PUBLIC void
r_fwd_update_forward_to(struct ccnr_handle * h, struct nameprefix_entry * npe);
PUBLIC void
r_fwd_append_debug_nonce(struct ccnr_handle * h, struct fdholder * fdholder, struct ccn_charbuf * cb);
PUBLIC void
r_fwd_append_plain_nonce(struct ccnr_handle * h, struct fdholder * fdholder, struct ccn_charbuf * cb);
PUBLIC int
r_fwd_propagate_interest(struct ccnr_handle * h,
				   struct fdholder * fdholder,
				   unsigned char *msg,
				   struct ccn_parsed_interest * pi,
				   struct nameprefix_entry * npe);
PUBLIC int
r_fwd_is_duplicate_flooded(struct ccnr_handle * h, unsigned char *msg,
					 struct ccn_parsed_interest * pi, unsigned filedesc);
PUBLIC int
r_fwd_nameprefix_seek(struct ccnr_handle * h, struct hashtb_enumerator * e,
				const unsigned char *msg, struct ccn_indexbuf * comps, int ncomps);
PUBLIC struct content_entry *
r_store_next_child_at_level(struct ccnr_handle * h,
					struct content_entry * content, int level);
PUBLIC void
r_store_mark_stale(struct ccnr_handle * h, struct content_entry * content);
PUBLIC void
r_store_set_content_timer(struct ccnr_handle * h, struct content_entry * content,
				  struct ccn_parsed_ContentObject * pco);
PUBLIC void
r_dispatch_process_internal_client_buffer(struct ccnr_handle * h);
PUBLIC void
r_link_do_deferred_write(struct ccnr_handle * h, int fd);
PUBLIC void
r_io_prepare_poll_fds(struct ccnr_handle * h);
PUBLIC void
r_util_reseed(struct ccnr_handle * h);
PUBLIC char    *
r_net_get_local_sockname(void);
PUBLIC void
r_util_gettime(const struct ccn_gettime * self, struct ccn_timeval * result);
PUBLIC int
r_net_listen_on_wildcards(struct ccnr_handle * h);
PUBLIC int
r_net_listen_on_address(struct ccnr_handle * h, const char *addr);
PUBLIC int
r_net_listen_on(struct ccnr_handle * h, const char *addrs);
PUBLIC void
r_io_shutdown_all(struct ccnr_handle * h);

//EOF
///bin/cat << //EOF >> ccnr_util.c
PUBLIC struct ccn_charbuf *
r_util_charbuf_obtain(struct ccnr_handle *h)
{
    struct ccn_charbuf *c = h->scratch_charbuf;
    if (c == NULL)
        return(ccn_charbuf_create());
    h->scratch_charbuf = NULL;
    c->length = 0;
    return(c);
}

PUBLIC void
r_util_charbuf_release(struct ccnr_handle *h, struct ccn_charbuf *c)
{
    c->length = 0;
    if (h->scratch_charbuf == NULL)
        h->scratch_charbuf = c;
    else
        ccn_charbuf_destroy(&c);
}

PUBLIC struct ccn_indexbuf *
r_util_indexbuf_obtain(struct ccnr_handle *h)
{
    struct ccn_indexbuf *c = h->scratch_indexbuf;
    if (c == NULL)
        return(ccn_indexbuf_create());
    h->scratch_indexbuf = NULL;
    c->n = 0;
    return(c);
}

PUBLIC void
r_util_indexbuf_release(struct ccnr_handle *h, struct ccn_indexbuf *c)
{
    c->n = 0;
    if (h->scratch_indexbuf == NULL)
        h->scratch_indexbuf = c;
    else
        ccn_indexbuf_destroy(&c);
}
//EOF
///bin/cat << //EOF >> ccnr_io.c

/**
 * Looks up a fdholder based on its filedesc (private).
 */
PUBLIC struct fdholder *
r_io_fdholder_from_fd(struct ccnr_handle *h, unsigned filedesc)
{
    unsigned slot = filedesc;
    struct fdholder *fdholder = NULL;
    if (slot < h->face_limit) {
        fdholder = h->fdholder_by_fd[slot];
        if (fdholder != NULL && fdholder->filedesc != filedesc)
            fdholder = NULL;
    }
    return(fdholder);
}

/**
 * Looks up a fdholder based on its filedesc.
 */
PUBLIC struct fdholder *
ccnr_r_io_fdholder_from_fd(struct ccnr_handle *h, unsigned filedesc)
{
    return(r_io_fdholder_from_fd(h, filedesc));
}

/**
 * Assigns the filedesc for a nacent fdholder,
 * calls r_io_register_new_face() if successful.
 */
PUBLIC int
r_io_enroll_face(struct ccnr_handle *h, struct fdholder *fdholder)
{
    unsigned i = fdholder->filedesc;
    unsigned n = h->face_limit;
    struct fdholder **a = h->fdholder_by_fd;
    if (i < n && a[i] == NULL) {
        if (a[i] == NULL)
            goto use_i;
        abort();
    }
    if (i > 65535)
        abort();
    a = realloc(a, (i + 1) * sizeof(struct fdholder *));
    if (a == NULL)
        return(-1); /* ENOMEM */
    h->face_limit = i + 1;
    while (n < h->face_limit)
        a[n++] = NULL;
    h->fdholder_by_fd = a;
use_i:
    a[i] = fdholder;
    fdholder->filedesc = i;
    fdholder->meter[FM_BYTI] = ccnr_meter_create(h, "bytein");
    fdholder->meter[FM_BYTO] = ccnr_meter_create(h, "byteout");
    fdholder->meter[FM_INTI] = ccnr_meter_create(h, "intrin");
    fdholder->meter[FM_INTO] = ccnr_meter_create(h, "introut");
    fdholder->meter[FM_DATI] = ccnr_meter_create(h, "datain");
    fdholder->meter[FM_DATO] = ccnr_meter_create(h, "dataout");
    r_io_register_new_face(h, fdholder);
    return (fdholder->filedesc);
}

//EOF
///bin/cat << //EOF >> ccnr_sendq.c

static int
choose_face_delay(struct ccnr_handle *h, struct fdholder *fdholder, enum cq_delay_class c)
{
    int shift = (c == CCN_CQ_SLOW) ? 2 : 0;
    if (c == CCN_CQ_ASAP)
        return(1);
    if ((fdholder->flags & CCN_FACE_LOCAL) != 0)
        return(5); /* local stream, answer quickly */
    if ((fdholder->flags & CCN_FACE_GG) != 0)
        return(100 << shift); /* localhost, delay just a little */
    if ((fdholder->flags & CCN_FACE_DGRAM) != 0)
        return(500 << shift); /* udp, delay just a little */
    return(100); /* probably tcp to a different machine */
}

static struct content_queue *
content_queue_create(struct ccnr_handle *h, struct fdholder *fdholder, enum cq_delay_class c)
{
    struct content_queue *q;
    unsigned usec;
    q = calloc(1, sizeof(*q));
    if (q != NULL) {
        usec = choose_face_delay(h, fdholder, c);
        q->burst_nsec = (usec <= 500 ? 500 : 150000); // XXX - needs a knob
        q->min_usec = usec;
        q->rand_usec = 2 * usec;
        q->nrun = 0;
        q->send_queue = ccn_indexbuf_create();
        if (q->send_queue == NULL) {
            free(q);
            return(NULL);
        }
        q->sender = NULL;
    }
    return(q);
}

PUBLIC void
r_sendq_content_queue_destroy(struct ccnr_handle *h, struct content_queue **pq)
{
    struct content_queue *q;
    if (*pq != NULL) {
        q = *pq;
        ccn_indexbuf_destroy(&q->send_queue);
        if (q->sender != NULL) {
            ccn_schedule_cancel(h->sched, q->sender);
            q->sender = NULL;
        }
        free(q);
        *pq = NULL;
    }
}
//EOF
///bin/cat << //EOF >> ccnr_io.c
/**
 * Close an open file descriptor quietly.
 */
static void
close_fd(int *pfd)
{
    if (*pfd != -1) {
        close(*pfd);
        *pfd = -1;
    }
}

/**
 * Close an open file descriptor, and grumble about it.
 */
static void
ccnr_close_fd(struct ccnr_handle *h, unsigned filedesc, int *pfd)
{
    int res;
    
    if (*pfd != -1) {
        int linger = 0;
        setsockopt(*pfd, SOL_SOCKET, SO_LINGER,
                   &linger, sizeof(linger));
        res = close(*pfd);
        if (res == -1)
            ccnr_msg(h, "close failed for fdholder %u fd=%d: %s (errno=%d)",
                     filedesc, *pfd, strerror(errno), errno);
        else
            ccnr_msg(h, "closing fd %d while finalizing fdholder %u", *pfd, filedesc);
        *pfd = -1;
    }
}

//EOF
///bin/cat << //EOF >> ccnr_store.c
PUBLIC struct content_entry *
r_store_content_from_accession(struct ccnr_handle *h, ccn_accession_t accession)
{
    struct content_entry *ans = NULL;
    if (accession < h->accession_base) {
        struct sparse_straggler_entry *entry;
        entry = hashtb_lookup(h->sparse_straggler_tab,
                              &accession, sizeof(accession));
        if (entry != NULL)
            ans = entry->content;
    }
    else if (accession < h->accession_base + h->content_by_accession_window) {
        ans = h->content_by_accession[accession - h->accession_base];
        if (ans != NULL && ans->accession != accession)
            ans = NULL;
    }
    return(ans);
}

static void
cleanout_stragglers(struct ccnr_handle *h)
{
    ccn_accession_t accession;
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct sparse_straggler_entry *entry = NULL;
    struct content_entry **a = h->content_by_accession;
    unsigned n_direct;
    unsigned n_occupied;
    unsigned window;
    unsigned i;
    if (h->accession <= h->accession_base || a[0] == NULL)
        return;
    n_direct = h->accession - h->accession_base;
    if (n_direct < 1000)
        return;
    n_occupied = hashtb_n(h->content_tab) - hashtb_n(h->sparse_straggler_tab);
    if (n_occupied >= (n_direct / 8))
        return;
    /* The direct lookup table is too sparse, so sweep stragglers */
    hashtb_start(h->sparse_straggler_tab, e);
    window = h->content_by_accession_window;
    for (i = 0; i < window; i++) {
        if (a[i] != NULL) {
            if (n_occupied >= ((window - i) / 8))
                break;
            accession = h->accession_base + i;
            hashtb_seek(e, &accession, sizeof(accession), 0);
            entry = e->data;
            if (entry != NULL && entry->content == NULL) {
                entry->content = a[i];
                a[i] = NULL;
                n_occupied -= 1;
            }
        }
    }
    hashtb_end(e);
}

static int
cleanout_empties(struct ccnr_handle *h)
{
    unsigned i = 0;
    unsigned j = 0;
    struct content_entry **a = h->content_by_accession;
    unsigned window = h->content_by_accession_window;
    if (a == NULL)
        return(-1);
    cleanout_stragglers(h);
    while (i < window && a[i] == NULL)
        i++;
    if (i == 0)
        return(-1);
    h->accession_base += i;
    while (i < window)
        a[j++] = a[i++];
    while (j < window)
        a[j++] = NULL;
    return(0);
}

PUBLIC void
r_store_enroll_content(struct ccnr_handle *h, struct content_entry *content)
{
    unsigned new_window;
    struct content_entry **new_array;
    struct content_entry **old_array;
    unsigned i = 0;
    unsigned j = 0;
    unsigned window = h->content_by_accession_window;
    if ((content->accession - h->accession_base) >= window &&
        cleanout_empties(h) < 0) {
        if (content->accession < h->accession_base)
            return;
        window = h->content_by_accession_window;
        old_array = h->content_by_accession;
        new_window = ((window + 20) * 3 / 2);
        if (new_window < window)
            return;
        new_array = calloc(new_window, sizeof(new_array[0]));
        if (new_array == NULL)
            return;
        while (i < h->content_by_accession_window && old_array[i] == NULL)
            i++;
        h->accession_base += i;
        h->content_by_accession = new_array;
        while (i < h->content_by_accession_window)
            new_array[j++] = old_array[i++];
        h->content_by_accession_window = new_window;
        free(old_array);
    }
    h->content_by_accession[content->accession - h->accession_base] = content;
}

static void
finalize_content(struct hashtb_enumerator *content_enumerator)
{
    struct ccnr_handle *h = hashtb_get_param(content_enumerator->ht, NULL);
    struct content_entry *entry = content_enumerator->data;
    unsigned i = entry->accession - h->accession_base;
    if (i < h->content_by_accession_window &&
          h->content_by_accession[i] == entry) {
        content_skiplist_remove(h, entry);
        h->content_by_accession[i] = NULL;
    }
    else {
        struct hashtb_enumerator ee;
        struct hashtb_enumerator *e = &ee;
        hashtb_start(h->sparse_straggler_tab, e);
        if (hashtb_seek(e, &entry->accession, sizeof(entry->accession), 0) ==
              HT_NEW_ENTRY) {
            ccnr_msg(h, "orphaned content %llu",
                     (unsigned long long)(entry->accession));
            hashtb_delete(e);
            hashtb_end(e);
            return;
        }
        content_skiplist_remove(h, entry);
        hashtb_delete(e);
        hashtb_end(e);
    }
    if (entry->comps != NULL) {
        free(entry->comps);
        entry->comps = NULL;
    }
}

static int
content_skiplist_findbefore(struct ccnr_handle *h,
                            const unsigned char *key,
                            size_t keysize,
                            struct content_entry *wanted_old,
                            struct ccn_indexbuf **ans)
{
    int i;
    int n = h->skiplinks->n;
    struct ccn_indexbuf *c;
    struct content_entry *content;
    int order;
    size_t start;
    size_t end;
    
    c = h->skiplinks;
    for (i = n - 1; i >= 0; i--) {
        for (;;) {
            if (c->buf[i] == 0)
                break;
            content = r_store_content_from_accession(h, c->buf[i]);
            if (content == NULL)
                abort();
            start = content->comps[0];
            end = content->comps[content->ncomps - 1];
            order = ccn_compare_names(content->key + start - 1, end - start + 2,
                                      key, keysize);
            if (order > 0)
                break;
            if (order == 0 && (wanted_old == content || wanted_old == NULL))
                break;
            if (content->skiplinks == NULL || i >= content->skiplinks->n)
                abort();
            c = content->skiplinks;
        }
        ans[i] = c;
    }
    return(n);
}

#define CCN_SKIPLIST_MAX_DEPTH 30
PUBLIC void
r_store_content_skiplist_insert(struct ccnr_handle *h, struct content_entry *content)
{
    int d;
    int i;
    size_t start;
    size_t end;
    struct ccn_indexbuf *pred[CCN_SKIPLIST_MAX_DEPTH] = {NULL};
    if (content->skiplinks != NULL) abort();
    for (d = 1; d < CCN_SKIPLIST_MAX_DEPTH - 1; d++)
        if ((nrand48(h->seed) & 3) != 0) break;
    while (h->skiplinks->n < d)
        ccn_indexbuf_append_element(h->skiplinks, 0);
    start = content->comps[0];
    end = content->comps[content->ncomps - 1];
    i = content_skiplist_findbefore(h,
                                    content->key + start - 1,
                                    end - start + 2, NULL, pred);
    if (i < d)
        d = i; /* just in case */
    content->skiplinks = ccn_indexbuf_create();
    for (i = 0; i < d; i++) {
        ccn_indexbuf_append_element(content->skiplinks, pred[i]->buf[i]);
        pred[i]->buf[i] = content->accession;
    }
}

static void
content_skiplist_remove(struct ccnr_handle *h, struct content_entry *content)
{
    int i;
    int d;
    size_t start;
    size_t end;
    struct ccn_indexbuf *pred[CCN_SKIPLIST_MAX_DEPTH] = {NULL};
    if (content->skiplinks == NULL) abort();
    start = content->comps[0];
    end = content->comps[content->ncomps - 1];
    d = content_skiplist_findbefore(h,
                                    content->key + start - 1,
                                    end - start + 2, content, pred);
    if (d > content->skiplinks->n)
        d = content->skiplinks->n;
    for (i = 0; i < d; i++) {
        pred[i]->buf[i] = content->skiplinks->buf[i];
    }
    ccn_indexbuf_destroy(&content->skiplinks);
}
//EOF
///bin/cat << //EOF >> ccnr_store.c

PUBLIC struct content_entry *
r_store_find_first_match_candidate(struct ccnr_handle *h,
                           const unsigned char *interest_msg,
                           const struct ccn_parsed_interest *pi)
{
    int res;
    struct ccn_indexbuf *pred[CCN_SKIPLIST_MAX_DEPTH] = {NULL};
    size_t start = pi->offset[CCN_PI_B_Name];
    size_t end = pi->offset[CCN_PI_E_Name];
    struct ccn_charbuf *namebuf = NULL;
    if (pi->offset[CCN_PI_B_Exclude] < pi->offset[CCN_PI_E_Exclude]) {
        /* Check for <Exclude><Any/><Component>... fast case */
        struct ccn_buf_decoder decoder;
        struct ccn_buf_decoder *d;
        size_t ex1start;
        size_t ex1end;
        d = ccn_buf_decoder_start(&decoder,
                                  interest_msg + pi->offset[CCN_PI_B_Exclude],
                                  pi->offset[CCN_PI_E_Exclude] -
                                  pi->offset[CCN_PI_B_Exclude]);
        ccn_buf_advance(d);
        if (ccn_buf_match_dtag(d, CCN_DTAG_Any)) {
            ccn_buf_advance(d);
            ccn_buf_check_close(d);
            if (ccn_buf_match_dtag(d, CCN_DTAG_Component)) {
                ex1start = pi->offset[CCN_PI_B_Exclude] + d->decoder.token_index;
                ccn_buf_advance_past_element(d);
                ex1end = pi->offset[CCN_PI_B_Exclude] + d->decoder.token_index;
                if (d->decoder.state >= 0) {
                    namebuf = ccn_charbuf_create();
                    ccn_charbuf_append(namebuf,
                                       interest_msg + start,
                                       end - start);
                    namebuf->length--;
                    ccn_charbuf_append(namebuf,
                                       interest_msg + ex1start,
                                       ex1end - ex1start);
                    ccn_charbuf_append_closer(namebuf);
                    if (h->debug & 8)
                        ccnr_debug_ccnb(h, __LINE__, "fastex", NULL,
                                        namebuf->buf, namebuf->length);
                }
            }
        }
    }
    if (namebuf == NULL) {
        res = content_skiplist_findbefore(h, interest_msg + start, end - start,
                                          NULL, pred);
    }
    else {
        res = content_skiplist_findbefore(h, namebuf->buf, namebuf->length,
                                          NULL, pred);
        ccn_charbuf_destroy(&namebuf);
    }
    if (res == 0)
        return(NULL);
    return(r_store_content_from_accession(h, pred[0]->buf[0]));
}
//EOF
///bin/cat << //EOF >> ccnr_store.c

PUBLIC int
r_store_content_matches_interest_prefix(struct ccnr_handle *h,
                                struct content_entry *content,
                                const unsigned char *interest_msg,
                                struct ccn_indexbuf *comps,
                                int prefix_comps)
{
    size_t prefixlen;
    if (prefix_comps < 0 || prefix_comps >= comps->n)
        abort();
    /* First verify the prefix match. */
    if (content->ncomps < prefix_comps + 1)
            return(0);
    prefixlen = comps->buf[prefix_comps] - comps->buf[0];
    if (content->comps[prefix_comps] - content->comps[0] != prefixlen)
        return(0);
    if (0 != memcmp(content->key + content->comps[0],
                    interest_msg + comps->buf[0],
                    prefixlen))
        return(0);
    return(1);
}
//EOF
///bin/cat << //EOF >> ccnr_store.c

PUBLIC ccn_accession_t
r_store_content_skiplist_next(struct ccnr_handle *h, struct content_entry *content)
{
    if (content == NULL)
        return(0);
    if (content->skiplinks == NULL || content->skiplinks->n < 1)
        return(0);
    return(content->skiplinks->buf[0]);
}
//EOF
///bin/cat << //EOF >> ccnr_match.c

PUBLIC void
r_match_consume_interest(struct ccnr_handle *h, struct propagating_entry *pe)
{
    struct fdholder *fdholder = NULL;
    ccn_indexbuf_destroy(&pe->outbound);
    if (pe->interest_msg != NULL) {
        free(pe->interest_msg);
        pe->interest_msg = NULL;
        fdholder = r_io_fdholder_from_fd(h, pe->filedesc);
        if (fdholder != NULL)
            fdholder->pending_interests -= 1;
    }
    if (pe->next != NULL) {
        pe->next->prev = pe->prev;
        pe->prev->next = pe->next;
        pe->next = pe->prev = NULL;
    }
    pe->usec = 0;
}
//EOF
///bin/cat << //EOF >> ccnr_forwarding.c
static struct nameprefix_entry *
nameprefix_for_pe(struct ccnr_handle * h, struct propagating_entry * pe);

static void
replan_propagation(struct ccnr_handle * h, struct propagating_entry * pe);

PUBLIC void
r_fwd_finalize_nameprefix(struct hashtb_enumerator *e)
{
    struct ccnr_handle *h = hashtb_get_param(e->ht, NULL);
    struct nameprefix_entry *npe = e->data;
    struct propagating_entry *head = &npe->pe_head;
    if (head->next != NULL) {
        while (head->next != head)
            r_match_consume_interest(h, head->next);
    }
    ccn_indexbuf_destroy(&npe->forward_to);
    ccn_indexbuf_destroy(&npe->tap);
    while (npe->forwarding != NULL) {
        struct ccn_forwarding *f = npe->forwarding;
        npe->forwarding = f->next;
        free(f);
    }
}

static void
link_propagating_interest_to_nameprefix(struct ccnr_handle *h,
    struct propagating_entry *pe, struct nameprefix_entry *npe)
{
    struct propagating_entry *head = &npe->pe_head;
    pe->next = head;
    pe->prev = head->prev;
    pe->prev->next = pe->next->prev = pe;
}

PUBLIC void
r_fwd_finalize_propagating(struct hashtb_enumerator *e)
{
    struct ccnr_handle *h = hashtb_get_param(e->ht, NULL);
    r_match_consume_interest(h, e->data);
}
//EOF
///bin/cat << //EOF >> ccnr_io.c

/**
 * Initialize the fdholder flags based upon the addr information
 * and the provided explicit setflags.
 */
static void
init_face_flags(struct ccnr_handle *h, struct fdholder *fdholder, int setflags)
{
    const struct sockaddr *addr = fdholder->addr;
    const unsigned char *rawaddr = NULL;
    
    if (addr->sa_family == AF_INET6) {
        const struct sockaddr_in6 *addr6 = (struct sockaddr_in6 *)addr;
        fdholder->flags |= CCN_FACE_INET6;
#ifdef IN6_IS_ADDR_LOOPBACK
        if (IN6_IS_ADDR_LOOPBACK(&addr6->sin6_addr))
            fdholder->flags |= CCN_FACE_LOOPBACK;
#endif
    }
    else if (addr->sa_family == AF_INET) {
        const struct sockaddr_in *addr4 = (struct sockaddr_in *)addr;
        rawaddr = (const unsigned char *)&addr4->sin_addr.s_addr;
        fdholder->flags |= CCN_FACE_INET;
        if (rawaddr[0] == 127)
            fdholder->flags |= CCN_FACE_LOOPBACK;
        else {
            /* If our side and the peer have the same address, consider it loopback */
            /* This is the situation inside of FreeBSD jail. */
            struct sockaddr_in myaddr;
            socklen_t myaddrlen = sizeof(myaddr);
            if (0 == getsockname(fdholder->recv_fd, (struct sockaddr *)&myaddr, &myaddrlen)) {
                if (addr4->sin_addr.s_addr == myaddr.sin_addr.s_addr)
                    fdholder->flags |= CCN_FACE_LOOPBACK;
            }
        }
    }
    else if (addr->sa_family == AF_UNIX)
        fdholder->flags |= (CCN_FACE_GG | CCN_FACE_LOCAL);
    fdholder->flags |= setflags;
}

/**
 * Make a new fdholder entered in the faces_by_fd table.
 */
PUBLIC struct fdholder *
r_io_record_connection(struct ccnr_handle *h, int fd,
                  struct sockaddr *who, socklen_t wholen,
                  int setflags)
{
    int res;
    struct fdholder *fdholder = NULL;
    unsigned char *addrspace;
    
    res = fcntl(fd, F_SETFL, O_NONBLOCK);
    if (res == -1)
        ccnr_msg(h, "fcntl: %s", strerror(errno));
    fdholder = calloc(1, sizeof(*fdholder));
    if (fdholder == NULL)
        return(fdholder);
    addrspace = calloc(1, wholen);
    if (addrspace != NULL) {
        memcpy(addrspace, who, wholen);
        fdholder->addrlen = wholen;
    }
    fdholder->addr = (struct sockaddr *)addrspace;
    fdholder->recv_fd = fd;
    fdholder->filedesc = fd;
    fdholder->sendface = CCN_NOFACEID;
    init_face_flags(h, fdholder, setflags);
    res = r_io_enroll_face(h, fdholder);
    if (res == -1) {
        if (addrspace != NULL)
            free(addrspace);
        free(fdholder);
        fdholder = NULL;
    }
    return(fdholder);
}

/**
 * Accept an incoming DGRAM_STREAM connection, creating a new fdholder.
 * @returns fd of new socket, or -1 for an error.
 */
PUBLIC int
r_io_accept_connection(struct ccnr_handle *h, int listener_fd)
{
    struct sockaddr_storage who;
    socklen_t wholen = sizeof(who);
    int fd;
    struct fdholder *fdholder;

    fd = accept(listener_fd, (struct sockaddr *)&who, &wholen);
    if (fd == -1) {
        ccnr_msg(h, "accept: %s", strerror(errno));
        return(-1);
    }
    fdholder = r_io_record_connection(h, fd,
                            (struct sockaddr *)&who, wholen,
                            CCN_FACE_UNDECIDED);
    if (fdholder == NULL)
        close_fd(&fd);
    else
        ccnr_msg(h, "accepted client fd=%d id=%u", fd, fdholder->filedesc);
    return(fd);
}

PUBLIC void
r_io_shutdown_client_fd(struct ccnr_handle *h, int fd)
{
    struct fdholder *fdholder = NULL;
    enum cq_delay_class c;
    int m;
    int res;
    
    fdholder = r_io_fdholder_from_fd(h, fd);
    if (fdholder == NULL) {
        ccnr_msg(h, "no fd holder for fd %d", fd);
        abort();
    }
    res = close(fd);
    ccnr_msg(h, "shutdown client fd=%d", fd);
    ccn_charbuf_destroy(&fdholder->inbuf);
    ccn_charbuf_destroy(&fdholder->outbuf);
    for (c = 0; c < CCN_CQ_N; c++)
        r_sendq_content_queue_destroy(h, &(fdholder->q[c]));
    if (fdholder->addr != NULL) {
        free(fdholder->addr);
		fdholder->addr = NULL;
    }
	for (m = 0; m < CCNR_FACE_METER_N; m++)
        ccnr_meter_destroy(&fdholder->meter[m]);
	if (h->fdholder_by_fd[fd] != fdholder) abort();
	h->fdholder_by_fd[fd] = NULL;
    free(fdholder);
    r_fwd_reap_needed(h, 250000);
}
//EOF
///bin/cat << //EOF >> ccnr_link.c

static int
ccn_stuff_interest(struct ccnr_handle * h,
				   struct fdholder * fdholder, struct ccn_charbuf * c);
static void
ccn_append_link_stuff(struct ccnr_handle * h,
					  struct fdholder * fdholder,
					  struct ccn_charbuf * c);


PUBLIC void
r_link_send_content(struct ccnr_handle *h, struct fdholder *fdholder, struct content_entry *content)
{
    int n, a, b, size;
    if ((fdholder->flags & CCN_FACE_NOSEND) != 0) {
        // XXX - should count this.
        return;
    }
    size = content->size;
    if (h->debug & 4)
        ccnr_debug_ccnb(h, __LINE__, "content_to", fdholder,
                        content->key, size);
    /* Excise the message-digest name component */
    n = content->ncomps;
    if (n < 2) abort();
    a = content->comps[n - 2];
    b = content->comps[n - 1];
    if (b - a != 36)
        abort(); /* strange digest length */
    r_link_stuff_and_send(h, fdholder, content->key, a, content->key + b, size - b);
    ccnr_meter_bump(h, fdholder->meter[FM_DATO], 1);
    h->content_items_sent += 1;
}
//EOF
///bin/cat << //EOF >> ccnr_sendq.c

static enum cq_delay_class
choose_content_delay_class(struct ccnr_handle *h, unsigned filedesc, int content_flags)
{
    struct fdholder *fdholder = r_io_fdholder_from_fd(h, filedesc);
    if (fdholder == NULL)
        return(CCN_CQ_ASAP); /* Going nowhere, get it over with */
    if ((fdholder->flags & (CCN_FACE_LINK | CCN_FACE_MCAST)) != 0) /* udplink or such, delay more */
        return((content_flags & CCN_CONTENT_ENTRY_SLOWSEND) ? CCN_CQ_SLOW : CCN_CQ_NORMAL);
    if ((fdholder->flags & CCN_FACE_DGRAM) != 0)
        return(CCN_CQ_NORMAL); /* udp, delay just a little */
    if ((fdholder->flags & (CCN_FACE_GG | CCN_FACE_LOCAL)) != 0)
        return(CCN_CQ_ASAP); /* localhost, answer quickly */
    return(CCN_CQ_NORMAL); /* default */
}

static unsigned
randomize_content_delay(struct ccnr_handle *h, struct content_queue *q)
{
    unsigned usec;
    
    usec = q->min_usec + q->rand_usec;
    if (usec < 2)
        return(1);
    if (usec <= 20 || q->rand_usec < 2) // XXX - what is a good value for this?
        return(usec); /* small value, don't bother to randomize */
    usec = q->min_usec + (nrand48(h->seed) % q->rand_usec);
    if (usec < 2)
        return(1);
    return(usec);
}

static int
content_sender(struct ccn_schedule *sched,
    void *clienth,
    struct ccn_scheduled_event *ev,
    int flags)
{
    int i, j;
    int delay;
    int nsec;
    int burst_nsec;
    int burst_max;
    struct ccnr_handle *h = clienth;
    struct content_entry *content = NULL;
    unsigned filedesc = ev->evint;
    struct fdholder *fdholder = NULL;
    struct content_queue *q = ev->evdata;
    (void)sched;
    
    if ((flags & CCN_SCHEDULE_CANCEL) != 0)
        goto Bail;
    fdholder = r_io_fdholder_from_fd(h, filedesc);
    if (fdholder == NULL)
        goto Bail;
    if (q->send_queue == NULL)
        goto Bail;
    if ((fdholder->flags & CCN_FACE_NOSEND) != 0)
        goto Bail;
    /* Send the content at the head of the queue */
    if (q->ready > q->send_queue->n ||
        (q->ready == 0 && q->nrun >= 12 && q->nrun < 120))
        q->ready = q->send_queue->n;
    nsec = 0;
    burst_nsec = q->burst_nsec;
    burst_max = 2;
    if (q->ready < burst_max)
        burst_max = q->ready;
    if (burst_max == 0)
        q->nrun = 0;
    for (i = 0; i < burst_max && nsec < 1000000; i++) {
        content = r_store_content_from_accession(h, q->send_queue->buf[i]);
        if (content == NULL)
            q->nrun = 0;
        else {
            r_link_send_content(h, fdholder, content);
            /* fdholder may have vanished, bail out if it did */
            if (r_io_fdholder_from_fd(h, filedesc) == NULL)
                goto Bail;
            nsec += burst_nsec * (unsigned)((content->size + 1023) / 1024);
            q->nrun++;
        }
    }
    if (q->ready < i) abort();
    q->ready -= i;
    /* Update queue */
    for (j = 0; i < q->send_queue->n; i++, j++)
        q->send_queue->buf[j] = q->send_queue->buf[i];
    q->send_queue->n = j;
    /* Do a poll before going on to allow others to preempt send. */
    delay = (nsec + 499) / 1000 + 1;
    if (q->ready > 0) {
        if (h->debug & 8)
            ccnr_msg(h, "fdholder %u ready %u delay %i nrun %u",
                     filedesc, q->ready, delay, q->nrun, fdholder->surplus);
        return(delay);
    }
    q->ready = j;
    if (q->nrun >= 12 && q->nrun < 120) {
        /* We seem to be a preferred provider, forgo the randomized delay */
        if (j == 0)
            delay += burst_nsec / 50;
        if (h->debug & 8)
            ccnr_msg(h, "fdholder %u ready %u delay %i nrun %u surplus %u",
                    (unsigned)ev->evint, q->ready, delay, q->nrun, fdholder->surplus);
        return(delay);
    }
    /* Determine when to run again */
    for (i = 0; i < q->send_queue->n; i++) {
        content = r_store_content_from_accession(h, q->send_queue->buf[i]);
        if (content != NULL) {
            q->nrun = 0;
            delay = randomize_content_delay(h, q);
            if (h->debug & 8)
                ccnr_msg(h, "fdholder %u queued %u delay %i",
                         (unsigned)ev->evint, q->ready, delay);
            return(delay);
        }
    }
    q->send_queue->n = q->ready = 0;
Bail:
    q->sender = NULL;
    return(0);
}

PUBLIC int
r_sendq_face_send_queue_insert(struct ccnr_handle *h,
                       struct fdholder *fdholder, struct content_entry *content)
{
    int ans;
    int delay;
    enum cq_delay_class c;
    enum cq_delay_class k;
    struct content_queue *q;
    if (fdholder == NULL || content == NULL || (fdholder->flags & CCN_FACE_NOSEND) != 0)
        return(-1);
    c = choose_content_delay_class(h, fdholder->filedesc, content->flags);
    if (fdholder->q[c] == NULL)
        fdholder->q[c] = content_queue_create(h, fdholder, c);
    q = fdholder->q[c];
    if (q == NULL)
        return(-1);
    /* Check the other queues first, it might be in one of them */
    for (k = 0; k < CCN_CQ_N; k++) {
        if (k != c && fdholder->q[k] != NULL) {
            ans = ccn_indexbuf_member(fdholder->q[k]->send_queue, content->accession);
            if (ans >= 0) {
                if (h->debug & 8)
                    ccnr_debug_ccnb(h, __LINE__, "content_otherq", fdholder,
                                    content->key, content->size);
                return(ans);
            }
        }
    }
    ans = ccn_indexbuf_set_insert(q->send_queue, content->accession);
    if (q->sender == NULL) {
        delay = randomize_content_delay(h, q);
        q->ready = q->send_queue->n;
        q->sender = ccn_schedule_event(h->sched, delay,
                                       content_sender, q, fdholder->filedesc);
        if (h->debug & 8)
            ccnr_msg(h, "fdholder %u q %d delay %d usec", fdholder->filedesc, c, delay);
    }
    return (ans);
}
//EOF
///bin/cat << //EOF >> ccnr_forwarding.c

/**
 * If the pe interest is slated to be sent to the given filedesc,
 * promote the filedesc to the front of the list, preserving the order
 * of the others.
 * @returns -1 if not found, or pe->sent if successful.
 */
static int
promote_outbound(struct propagating_entry *pe, unsigned filedesc)
{
    struct ccn_indexbuf *ob = pe->outbound;
    int lb = pe->sent;
    int i;
    if (ob == NULL || ob->n <= lb || lb < 0)
        return(-1);
    for (i = ob->n - 1; i >= lb; i--)
        if (ob->buf[i] == filedesc)
            break;
    if (i < lb)
        return(-1);
    for (; i > lb; i--)
        ob->buf[i] = ob->buf[i-1];
    ob->buf[lb] = filedesc;
    return(lb);
}
//EOF
///bin/cat << //EOF >> ccnr_match.c

/**
 * Consume matching interests
 * given a nameprefix_entry and a piece of content.
 *
 * If fdholder is not NULL, pay attention only to interests from that fdholder.
 * It is allowed to pass NULL for pc, but if you have a (valid) one it
 * will avoid a re-parse.
 * @returns number of matches found.
 */
PUBLIC int
r_match_consume_matching_interests(struct ccnr_handle *h,
                           struct nameprefix_entry *npe,
                           struct content_entry *content,
                           struct ccn_parsed_ContentObject *pc,
                           struct fdholder *fdholder)
{
    int matches = 0;
    struct propagating_entry *head;
    struct propagating_entry *next;
    struct propagating_entry *p;
    const unsigned char *content_msg;
    size_t content_size;
    struct fdholder *f;
    
    head = &npe->pe_head;
    content_msg = content->key;
    content_size = content->size;
    f = fdholder;
    for (p = head->next; p != head; p = next) {
        next = p->next;
        if (p->interest_msg != NULL &&
            ((fdholder == NULL && (f = r_io_fdholder_from_fd(h, p->filedesc)) != NULL) ||
             (fdholder != NULL && p->filedesc == fdholder->filedesc))) {
            if (ccn_content_matches_interest(content_msg, content_size, 0, pc,
                                             p->interest_msg, p->size, NULL)) {
                r_sendq_face_send_queue_insert(h, f, content);
                if (h->debug & (32 | 8))
                    ccnr_debug_ccnb(h, __LINE__, "consume", f,
                                    p->interest_msg, p->size);
                matches += 1;
                r_match_consume_interest(h, p);
            }
        }
    }
    return(matches);
}
//EOF
///bin/cat << //EOF >> ccnr_forwarding.c

PUBLIC void
r_fwd_adjust_npe_predicted_response(struct ccnr_handle *h,
                              struct nameprefix_entry *npe, int up)
{
    unsigned t = npe->usec;
    if (up)
        t = t + (t >> 3);
    else
        t = t - (t >> 7);
    if (t < 127)
        t = 127;
    else if (t > 1000000)
        t = 1000000;
    npe->usec = t;
}

static void
adjust_predicted_response(struct ccnr_handle *h,
                          struct propagating_entry *pe, int up)
{
    struct nameprefix_entry *npe;
        
    npe = nameprefix_for_pe(h, pe);
    if (npe == NULL)
        return;
    r_fwd_adjust_npe_predicted_response(h, npe, up);
    if (npe->parent != NULL)
        r_fwd_adjust_npe_predicted_response(h, npe->parent, up);
}
//EOF
///bin/cat << //EOF >> ccnr_match.c

/**
 * Keep a little history about where matching content comes from.
 */
static void
note_content_from(struct ccnr_handle *h,
                  struct nameprefix_entry *npe,
                  unsigned from_faceid,
                  int prefix_comps)
{
    if (npe->src == from_faceid)
        r_fwd_adjust_npe_predicted_response(h, npe, 0);
    else if (npe->src == CCN_NOFACEID)
        npe->src = from_faceid;
    else {
        npe->osrc = npe->src;
        npe->src = from_faceid;
    }
    if (h->debug & 8)
        ccnr_msg(h, "sl.%d %u ci=%d osrc=%u src=%u usec=%d", __LINE__,
                 from_faceid, prefix_comps, npe->osrc, npe->src, npe->usec);
}
//EOF
///bin/cat << //EOF >> ccnr_forwarding.c

/**
 * Use the history to reorder the interest forwarding.
 *
 * @returns number of tap faces that are present.
 */
static int
reorder_outbound_using_history(struct ccnr_handle *h,
                               struct nameprefix_entry *npe,
                               struct propagating_entry *pe)
{
    int ntap = 0;
    int i;
    
    if (npe->osrc != CCN_NOFACEID)
        promote_outbound(pe, npe->osrc);
    /* Process npe->src last so it will be tried first */
    if (npe->src != CCN_NOFACEID)
        promote_outbound(pe, npe->src);
    /* Tap are really first. */
    if (npe->tap != NULL) {
        ntap = npe->tap->n;
        for (i = 0; i < ntap; i++)
            promote_outbound(pe, npe->tap->buf[i]);
    }
    return(ntap);
}
//EOF
///bin/cat << //EOF >> ccnr_match.c

/**
 * Find and consume interests that match given content.
 *
 * Schedules the sending of the content.
 * If fdholder is not NULL, pay attention only to interests from that fdholder.
 * It is allowed to pass NULL for pc, but if you have a (valid) one it
 * will avoid a re-parse.
 * For new content, from_face is the source; for old content, from_face is NULL.
 * @returns number of matches, or -1 if the new content should be dropped.
 */
PUBLIC int
r_match_match_interests(struct ccnr_handle *h, struct content_entry *content,
                           struct ccn_parsed_ContentObject *pc,
                           struct fdholder *fdholder, struct fdholder *from_face)
{
    int n_matched = 0;
    int new_matches;
    int ci;
    int cm = 0;
    unsigned c0 = content->comps[0];
    const unsigned char *key = content->key + c0;
    struct nameprefix_entry *npe = NULL;
    for (ci = content->ncomps - 1; ci >= 0; ci--) {
        int size = content->comps[ci] - c0;
        npe = hashtb_lookup(h->nameprefix_tab, key, size);
        if (npe != NULL)
            break;
    }
    for (; npe != NULL; npe = npe->parent, ci--) {
        if (npe->fgen != h->forward_to_gen)
            r_fwd_update_forward_to(h, npe);
        if (from_face != NULL && (npe->flags & CCN_FORW_LOCAL) != 0 &&
            (from_face->flags & CCN_FACE_GG) == 0)
            return(-1);
        new_matches = r_match_consume_matching_interests(h, npe, content, pc, fdholder);
        if (from_face != NULL && (new_matches != 0 || ci + 1 == cm))
            note_content_from(h, npe, from_face->filedesc, ci);
        if (new_matches != 0) {
            cm = ci; /* update stats for this prefix and one shorter */
            n_matched += new_matches;
        }
    }
    return(n_matched);
}
//EOF
///bin/cat << //EOF >> ccnr_link.c

/**
 * Send a message in a PDU, possibly stuffing other interest messages into it.
 * The message may be in two pieces.
 */
PUBLIC void
r_link_stuff_and_send(struct ccnr_handle *h, struct fdholder *fdholder,
               const unsigned char *data1, size_t size1,
               const unsigned char *data2, size_t size2) {
    struct ccn_charbuf *c = NULL;
    
    if ((fdholder->flags & CCN_FACE_LINK) != 0) {
        c = r_util_charbuf_obtain(h);
        ccn_charbuf_reserve(c, size1 + size2 + 5 + 8);
        ccn_charbuf_append_tt(c, CCN_DTAG_CCNProtocolDataUnit, CCN_DTAG);
        ccn_charbuf_append(c, data1, size1);
        if (size2 != 0)
            ccn_charbuf_append(c, data2, size2);
        ccn_stuff_interest(h, fdholder, c);
        ccn_append_link_stuff(h, fdholder, c);
        ccn_charbuf_append_closer(c);
    }
    else if (size2 != 0 || 1 > size1 + size2 ||
             (fdholder->flags & (CCN_FACE_SEQOK | CCN_FACE_SEQPROBE)) != 0) {
        c = r_util_charbuf_obtain(h);
        ccn_charbuf_append(c, data1, size1);
        if (size2 != 0)
            ccn_charbuf_append(c, data2, size2);
        ccn_stuff_interest(h, fdholder, c);
        ccn_append_link_stuff(h, fdholder, c);
    }
    else {
        /* avoid a copy in this case */
        r_io_send(h, fdholder, data1, size1);
        return;
    }
    r_io_send(h, fdholder, c->buf, c->length);
    r_util_charbuf_release(h, c);
    return;
}

/**
 * Stuff a PDU with interest messages that will fit.
 *
 * Note by default stuffing does not happen due to the setting of h->mtu.
 * @returns the number of messages that were stuffed.
 */
static int
ccn_stuff_interest(struct ccnr_handle *h,
                   struct fdholder *fdholder, struct ccn_charbuf *c)
{
    int n_stuffed = 0;
    return(n_stuffed);
}

PUBLIC void
r_link_ccn_link_state_init(struct ccnr_handle *h, struct fdholder *fdholder)
{
    int checkflags;
    int matchflags;
    
    matchflags = CCN_FACE_DGRAM;
    checkflags = matchflags | CCN_FACE_MCAST | CCN_FACE_GG | CCN_FACE_SEQOK | \
                 CCN_FACE_PASSIVE;
    if ((fdholder->flags & checkflags) != matchflags)
        return;
    /* Send one sequence number to see if the other side wants to play. */
    fdholder->pktseq = nrand48(h->seed);
    fdholder->flags |= CCN_FACE_SEQPROBE;
}

static void
ccn_append_link_stuff(struct ccnr_handle *h,
                      struct fdholder *fdholder,
                      struct ccn_charbuf *c)
{
    if ((fdholder->flags & (CCN_FACE_SEQOK | CCN_FACE_SEQPROBE)) == 0)
        return;
    ccn_charbuf_append_tt(c, CCN_DTAG_SequenceNumber, CCN_DTAG);
    ccn_charbuf_append_tt(c, 2, CCN_BLOB);
    ccn_charbuf_append_value(c, fdholder->pktseq, 2);
    ccnb_element_end(c);
    if (0)
        ccnr_msg(h, "debug.%d pkt_to %u seq %u",
                 __LINE__, fdholder->filedesc, (unsigned)fdholder->pktseq);
    fdholder->pktseq++;
    fdholder->flags &= ~CCN_FACE_SEQPROBE;
}

PUBLIC int
r_link_process_incoming_link_message(struct ccnr_handle *h,
                              struct fdholder *fdholder, enum ccn_dtag dtag,
                              unsigned char *msg, size_t size)
{
    uintmax_t s;
    int checkflags;
    int matchflags;
    struct ccn_buf_decoder decoder;
    struct ccn_buf_decoder *d = ccn_buf_decoder_start(&decoder, msg, size);

    switch (dtag) {
        case CCN_DTAG_SequenceNumber:
            s = ccn_parse_required_tagged_binary_number(d, dtag, 1, 6);
            if (d->decoder.state < 0)
                return(d->decoder.state);
            /*
             * If the other side is unicast and sends sequence numbers,
             * then it is OK for us to send numbers as well.
             */
            matchflags = CCN_FACE_DGRAM;
            checkflags = matchflags | CCN_FACE_MCAST | CCN_FACE_SEQOK;
            if ((fdholder->flags & checkflags) == matchflags)
                fdholder->flags |= CCN_FACE_SEQOK;
            if (fdholder->rrun == 0) {
                fdholder->rseq = s;
                fdholder->rrun = 1;
                return(0);
            }
            if (s == fdholder->rseq + 1) {
                fdholder->rseq = s;
                if (fdholder->rrun < 255)
                    fdholder->rrun++;
                return(0);
            }
            if (s > fdholder->rseq && s - fdholder->rseq < 255) {
                ccnr_msg(h, "seq_gap %u %ju to %ju",
                         fdholder->filedesc, fdholder->rseq, s);
                fdholder->rseq = s;
                fdholder->rrun = 1;
                return(0);
            }
            if (s <= fdholder->rseq) {
                if (fdholder->rseq - s < fdholder->rrun) {
                    ccnr_msg(h, "seq_dup %u %ju", fdholder->filedesc, s);
                    return(0);
                }
                if (fdholder->rseq - s < 255) {
                    /* Received out of order */
                    ccnr_msg(h, "seq_ooo %u %ju", fdholder->filedesc, s);
                    if (s == fdholder->rseq - fdholder->rrun) {
                        fdholder->rrun++;
                        return(0);
                    }
                }
            }
            fdholder->rseq = s;
            fdholder->rrun = 1;
            break;
        default:
            return(-1);
    }
    return(0);
}
//EOF
///bin/cat << //EOF >> ccnr_io.c

/**
 * Destroys the fdholder identified by filedesc.
 * @returns 0 for success, -1 for failure.
 */
PUBLIC int
r_io_destroy_face(struct ccnr_handle *h, unsigned filedesc)
{
    r_io_shutdown_client_fd(h, filedesc);
    return(0);
}
//EOF
///bin/cat << //EOF >> ccnr_forwarding.c

/**
 * Remove expired faces from npe->forward_to
 */
static void
check_forward_to(struct ccnr_handle *h, struct nameprefix_entry *npe)
{
    struct ccn_indexbuf *ft = npe->forward_to;
    int i;
    int j;
    if (ft == NULL)
        return;
    for (i = 0; i < ft->n; i++)
        if (r_io_fdholder_from_fd(h, ft->buf[i]) == NULL)
            break;
    for (j = i + 1; j < ft->n; j++)
        if (r_io_fdholder_from_fd(h, ft->buf[j]) != NULL)
            ft->buf[i++] = ft->buf[j];
    if (i == 0)
        ccn_indexbuf_destroy(&npe->forward_to);
    else if (i < ft->n)
        ft->n = i;
}

/**
 * Check for expired propagating interests.
 * @returns number that have gone away.
 */
static int
check_propagating(struct ccnr_handle *h)
{
    int count = 0;
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct propagating_entry *pe;
    
    hashtb_start(h->propagating_tab, e);
    for (pe = e->data; pe != NULL; pe = e->data) {
        if (pe->interest_msg == NULL) {
            if (pe->size == 0) {
                count += 1;
                hashtb_delete(e);
                continue;
            }
            pe->size = (pe->size > 1); /* go around twice */
            /* XXX - could use a flag bit instead of hacking size */
        }
        hashtb_next(e);
    }
    hashtb_end(e);
    return(count);
}

/**
 * Ages src info and retires unused nameprefix entries.
 * @returns number that have gone away.
 */
static int
check_nameprefix_entries(struct ccnr_handle *h)
{
    int count = 0;
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct propagating_entry *head;
    struct nameprefix_entry *npe;    
    
    hashtb_start(h->nameprefix_tab, e);
    for (npe = e->data; npe != NULL; npe = e->data) {
        if (npe->forward_to != NULL)
            check_forward_to(h, npe);
        if (  npe->src == CCN_NOFACEID &&
              npe->children == 0 &&
              npe->forwarding == NULL) {
            head = &npe->pe_head;
            if (head == head->next) {
                count += 1;
                if (npe->parent != NULL) {
                    npe->parent->children--;
                    npe->parent = NULL;
                }
                hashtb_delete(e);
                continue;
            }
        }
        npe->osrc = npe->src;
        npe->src = CCN_NOFACEID;
        hashtb_next(e);
    }
    hashtb_end(e);
    return(count);
}

/**
 * Scheduled reap event for retiring expired structures.
 */
static int
reap(struct ccn_schedule *sched,
    void *clienth,
    struct ccn_scheduled_event *ev,
    int flags)
{
    struct ccnr_handle *h = clienth;
    (void)(sched);
    (void)(ev);
    if ((flags & CCN_SCHEDULE_CANCEL) != 0) {
        h->reaper = NULL;
        return(0);
    }
    check_propagating(h);
    check_nameprefix_entries(h);
    return(2 * CCN_INTEREST_LIFETIME_MICROSEC);
}

PUBLIC void
r_fwd_reap_needed(struct ccnr_handle *h, int init_delay_usec)
{
    if (h->reaper == NULL)
        h->reaper = ccn_schedule_event(h->sched, init_delay_usec, reap, NULL, 0);
}
//EOF
///bin/cat << //EOF >> ccnr_store.c

PUBLIC int
r_store_remove_content(struct ccnr_handle *h, struct content_entry *content)
{
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    int res;
    if (content == NULL)
        return(-1);
    hashtb_start(h->content_tab, e);
    res = hashtb_seek(e, content->key,
                      content->key_size, content->size - content->key_size);
    if (res != HT_OLD_ENTRY)
        abort();
    if ((content->flags & CCN_CONTENT_ENTRY_STALE) != 0)
        h->n_stale--;
    if (h->debug & 4)
        ccnr_debug_ccnb(h, __LINE__, "remove", NULL,
                        content->key, content->size);
    hashtb_delete(e);
    hashtb_end(e);
    return(0);
}
//EOF
///bin/cat << //EOF >> ccnr_forwarding.c

/**
 * Age out the old forwarding table entries
 */
static int
age_forwarding(struct ccn_schedule *sched,
             void *clienth,
             struct ccn_scheduled_event *ev,
             int flags)
{
    struct ccnr_handle *h = clienth;
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct ccn_forwarding *f;
    struct ccn_forwarding *next;
    struct ccn_forwarding **p;
    struct nameprefix_entry *npe;
    
    if ((flags & CCN_SCHEDULE_CANCEL) != 0) {
        h->age_forwarding = NULL;
        return(0);
    }
    hashtb_start(h->nameprefix_tab, e);
    for (npe = e->data; npe != NULL; npe = e->data) {
        p = &npe->forwarding;
        for (f = npe->forwarding; f != NULL; f = next) {
            next = f->next;
            if ((f->flags & CCN_FORW_REFRESHED) == 0 ||
                  r_io_fdholder_from_fd(h, f->filedesc) == NULL) {
                if (h->debug & 2) {
                    struct fdholder *fdholder = r_io_fdholder_from_fd(h, f->filedesc);
                    if (fdholder != NULL) {
                        struct ccn_charbuf *prefix = ccn_charbuf_create();
                        ccn_name_init(prefix);
                        ccn_name_append_components(prefix, e->key, 0, e->keysize);
                        ccnr_debug_ccnb(h, __LINE__, "prefix_expiry", fdholder,
                                prefix->buf,
                                prefix->length);
                        ccn_charbuf_destroy(&prefix);
                    }
                }
                *p = next;
                free(f);
                f = NULL;
                continue;
            }
            f->expires -= CCN_FWU_SECS;
            if (f->expires <= 0)
                f->flags &= ~CCN_FORW_REFRESHED;
            p = &(f->next);
        }
        hashtb_next(e);
    }
    hashtb_end(e);
    h->forward_to_gen += 1;
    return(CCN_FWU_SECS*1000000);
}

PUBLIC void
r_fwd_age_forwarding_needed(struct ccnr_handle *h)
{
    if (h->age_forwarding == NULL)
        h->age_forwarding = ccn_schedule_event(h->sched,
                                               CCN_FWU_SECS*1000000,
                                               age_forwarding,
                                               NULL, 0);
}

static struct ccn_forwarding *
seek_forwarding(struct ccnr_handle *h,
                struct nameprefix_entry *npe, unsigned filedesc)
{
    struct ccn_forwarding *f;
    
    for (f = npe->forwarding; f != NULL; f = f->next)
        if (f->filedesc == filedesc)
            return(f);
    f = calloc(1, sizeof(*f));
    if (f != NULL) {
        f->filedesc = filedesc;
        f->flags = (CCN_FORW_CHILD_INHERIT | CCN_FORW_ACTIVE);
        f->expires = 0x7FFFFFFF;
        f->next = npe->forwarding;
        npe->forwarding = f;
    }
    return(f);
}

/**
 * Register or update a prefix in the forwarding table (FIB).
 *
 * @param h is the ccnr handle.
 * @param msg is a ccnb-encoded message containing the name prefix somewhere.
 * @param comps contains the delimiting offsets for the name components in msg.
 * @param ncomps is the number of relevant components.
 * @param filedesc indicates which fdholder to forward to.
 * @param flags are the forwarding entry flags (CCN_FORW_...), -1 for defaults.
 * @param expires tells the remaining lifetime, in seconds.
 * @returns -1 for error, or new flags upon success; the private flag
 *        CCN_FORW_REFRESHED indicates a previously existing entry.
 */
static int
ccnr_reg_prefix(struct ccnr_handle *h,
                const unsigned char *msg,
                struct ccn_indexbuf *comps,
                int ncomps,
                unsigned filedesc,
                int flags,
                int expires)
{
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct ccn_forwarding *f = NULL;
    struct nameprefix_entry *npe = NULL;
    int res;
    struct fdholder *fdholder = NULL;
    
    if (flags >= 0 &&
        (flags & CCN_FORW_PUBMASK) != flags)
        return(-1);
    fdholder = r_io_fdholder_from_fd(h, filedesc);
    if (fdholder == NULL)
        return(-1);
    /* This is a bit hacky, but it gives us a way to set CCN_FACE_DC */
    if (flags >= 0 && (flags & CCN_FORW_LAST) != 0)
        fdholder->flags |= CCN_FACE_DC;
    hashtb_start(h->nameprefix_tab, e);
    res = r_fwd_nameprefix_seek(h, e, msg, comps, ncomps);
    if (res >= 0) {
        res = (res == HT_OLD_ENTRY) ? CCN_FORW_REFRESHED : 0;
        npe = e->data;
        f = seek_forwarding(h, npe, filedesc);
        if (f != NULL) {
            h->forward_to_gen += 1; // XXX - too conservative, should check changes
            f->expires = expires;
            if (flags < 0)
                flags = f->flags & CCN_FORW_PUBMASK;
            f->flags = (CCN_FORW_REFRESHED | flags);
            res |= flags;
            if (h->debug & (2 | 4)) {
                struct ccn_charbuf *prefix = ccn_charbuf_create();
                struct ccn_charbuf *debugtag = ccn_charbuf_create();
                ccn_charbuf_putf(debugtag, "prefix,ff=%s%x",
                                 flags > 9 ? "0x" : "", flags);
                if (f->expires < (1 << 30))
                    ccn_charbuf_putf(debugtag, ",sec=%d", expires);
                ccn_name_init(prefix);
                ccn_name_append_components(prefix, msg,
                                           comps->buf[0], comps->buf[ncomps]);
                ccnr_debug_ccnb(h, __LINE__,
                                ccn_charbuf_as_string(debugtag),
                                fdholder,
                                prefix->buf,
                                prefix->length);
                ccn_charbuf_destroy(&prefix);
                ccn_charbuf_destroy(&debugtag);
            }
        }
        else
            res = -1;
    }
    hashtb_end(e);
    return(res);
}

/**
 * Register a prefix, expressed in the form of a URI.
 * @returns negative value for error, or new fdholder flags for success.
 */
PUBLIC int
r_fwd_reg_uri(struct ccnr_handle *h,
             const char *uri,
             unsigned filedesc,
             int flags,
             int expires)
{
    struct ccn_charbuf *name;
    struct ccn_buf_decoder decoder;
    struct ccn_buf_decoder *d;
    struct ccn_indexbuf *comps;
    int res;
    
    name = ccn_charbuf_create();
    ccn_name_init(name);
    res = ccn_name_from_uri(name, uri);
    if (res < 0)
        goto Bail;
    comps = ccn_indexbuf_create();
    d = ccn_buf_decoder_start(&decoder, name->buf, name->length);
    res = ccn_parse_Name(d, comps);
    if (res < 0)
        goto Bail;
    res = ccnr_reg_prefix(h, name->buf, comps, comps->n - 1,
                          filedesc, flags, expires);
Bail:
    ccn_charbuf_destroy(&name);
    ccn_indexbuf_destroy(&comps);
    return(res);
}

/**
 * Register prefixes, expressed in the form of a list of URIs.
 * The URIs in the charbuf are each terminated by nul.
 */
PUBLIC void
r_fwd_reg_uri_list(struct ccnr_handle *h,
             struct ccn_charbuf *uris,
             unsigned filedesc,
             int flags,
             int expires)
{
    size_t i;
    const char *s;
    s = ccn_charbuf_as_string(uris);
    for (i = 0; i + 1 < uris->length; i += strlen(s + i) + 1)
        r_fwd_reg_uri(h, s + i, filedesc, flags, expires);
}
//EOF
///bin/cat << //EOF >> ccnr_io.c

/**
 * Called when a fdholder is first created, and (perhaps) a second time in the case
 * that a fdholder transitions from the undecided state.
 */
PUBLIC void
r_io_register_new_face(struct ccnr_handle *h, struct fdholder *fdholder)
{
    if (fdholder->filedesc != 0 && (fdholder->flags & (CCN_FACE_UNDECIDED | CCN_FACE_PASSIVE)) == 0) {
        ccnr_face_status_change(h, fdholder->filedesc);
        r_link_ccn_link_state_init(h, fdholder);
    }
}
//EOF
///bin/cat << //EOF >> ccnr_forwarding.c

/**
 * Recompute the contents of npe->forward_to and npe->flags
 * from forwarding lists of npe and all of its ancestors.
 */
PUBLIC void
r_fwd_update_forward_to(struct ccnr_handle *h, struct nameprefix_entry *npe)
{
    struct ccn_indexbuf *x = NULL;
    struct ccn_indexbuf *tap = NULL;
    struct ccn_forwarding *f = NULL;
    struct nameprefix_entry *p = NULL;
    unsigned tflags;
    unsigned wantflags;
    unsigned moreflags;
    unsigned lastfaceid;
    unsigned namespace_flags;
    /* tap_or_last flag bit is used only in this procedure */
    unsigned tap_or_last = (1U << 31);

    x = npe->forward_to;
    if (x == NULL)
        npe->forward_to = x = ccn_indexbuf_create();
    else
        x->n = 0;
    wantflags = CCN_FORW_ACTIVE;
    lastfaceid = CCN_NOFACEID;
    namespace_flags = 0;
    for (p = npe; p != NULL; p = p->parent) {
        moreflags = CCN_FORW_CHILD_INHERIT;
        for (f = p->forwarding; f != NULL; f = f->next) {
            if (r_io_fdholder_from_fd(h, f->filedesc) == NULL)
                continue;
            tflags = f->flags;
            if (tflags & (CCN_FORW_TAP | CCN_FORW_LAST))
                tflags |= tap_or_last;
            if ((tflags & wantflags) == wantflags) {
                if (h->debug & 32)
                    ccnr_msg(h, "fwd.%d adding %u", __LINE__, f->filedesc);
                ccn_indexbuf_set_insert(x, f->filedesc);
                if ((f->flags & CCN_FORW_TAP) != 0) {
                    if (tap == NULL)
                        tap = ccn_indexbuf_create();
                    ccn_indexbuf_set_insert(tap, f->filedesc);
                }
                if ((f->flags & CCN_FORW_LAST) != 0)
                    lastfaceid = f->filedesc;
            }
            namespace_flags |= f->flags;
            if ((f->flags & CCN_FORW_CAPTURE) != 0)
                moreflags |= tap_or_last;
        }
        wantflags |= moreflags;
    }
    if (lastfaceid != CCN_NOFACEID)
        ccn_indexbuf_move_to_end(x, lastfaceid);
    npe->flags = namespace_flags;
    npe->fgen = h->forward_to_gen;
    if (x->n == 0)
        ccn_indexbuf_destroy(&npe->forward_to);
    ccn_indexbuf_destroy(&npe->tap);
    npe->tap = tap;
}

/**
 * This is where we consult the interest forwarding table.
 * @param h is the ccnr handle
 * @param from is the handle for the originating fdholder (may be NULL).
 * @param msg points to the ccnb-encoded interest message
 * @param pi must be the parse information for msg
 * @param npe should be the result of the prefix lookup
 * @result Newly allocated set of outgoing faceids (never NULL)
 */
static struct ccn_indexbuf *
get_outbound_faces(struct ccnr_handle *h,
    struct fdholder *from,
    unsigned char *msg,
    struct ccn_parsed_interest *pi,
    struct nameprefix_entry *npe)
{
    int checkmask = 0;
    int wantmask = 0;
    struct ccn_indexbuf *x;
    struct fdholder *fdholder;
    int i;
    int n;
    unsigned filedesc;
    
    while (npe->parent != NULL && npe->forwarding == NULL)
        npe = npe->parent;
    if (npe->fgen != h->forward_to_gen)
        r_fwd_update_forward_to(h, npe);
    x = ccn_indexbuf_create();
    if (pi->scope == 0 || npe->forward_to == NULL || npe->forward_to->n == 0)
        return(x);
    if ((npe->flags & CCN_FORW_LOCAL) != 0)
        checkmask = (from != NULL && (from->flags & CCN_FACE_GG) != 0) ? CCN_FACE_GG : (~0);
    else if (pi->scope == 1)
        checkmask = CCN_FACE_GG;
    else if (pi->scope == 2)
        checkmask = from ? (CCN_FACE_GG & ~(from->flags)) : ~0;
    wantmask = checkmask;
    if (wantmask == CCN_FACE_GG)
        checkmask |= CCN_FACE_DC;
    for (n = npe->forward_to->n, i = 0; i < n; i++) {
        filedesc = npe->forward_to->buf[i];
        fdholder = r_io_fdholder_from_fd(h, filedesc);
        if (fdholder != NULL && fdholder != from &&
            ((fdholder->flags & checkmask) == wantmask)) {
            if (h->debug & 32)
                ccnr_msg(h, "outbound.%d adding %u", __LINE__, fdholder->filedesc);
            ccn_indexbuf_append_element(x, fdholder->filedesc);
        }
    }
    return(x);
}

static int
pe_next_usec(struct ccnr_handle *h,
             struct propagating_entry *pe, int next_delay, int lineno)
{
    if (next_delay > pe->usec)
        next_delay = pe->usec;
    pe->usec -= next_delay;
    if (h->debug & 32) {
        struct ccn_charbuf *c = ccn_charbuf_create();
        ccn_charbuf_putf(c, "%p.%dof%d,usec=%d+%d",
                         (void *)pe,
                         pe->sent,
                         pe->outbound ? pe->outbound->n : -1,
                         next_delay, pe->usec);
        if (pe->interest_msg != NULL) {
            ccnr_debug_ccnb(h, lineno, ccn_charbuf_as_string(c),
                            r_io_fdholder_from_fd(h, pe->filedesc),
                            pe->interest_msg, pe->size);
        }
        ccn_charbuf_destroy(&c);
    }
    return(next_delay);
}

static int
do_propagate(struct ccn_schedule *sched,
             void *clienth,
             struct ccn_scheduled_event *ev,
             int flags)
{
    struct ccnr_handle *h = clienth;
    struct propagating_entry *pe = ev->evdata;
    (void)(sched);
    int next_delay = 1;
    int special_delay = 0;
    if (pe->interest_msg == NULL)
        return(0);
    if (flags & CCN_SCHEDULE_CANCEL) {
        r_match_consume_interest(h, pe);
        return(0);
    }
    if ((pe->flags & CCN_PR_WAIT1) != 0) {
        pe->flags &= ~CCN_PR_WAIT1;
        adjust_predicted_response(h, pe, 1);
    }
    if (pe->usec <= 0) {
        if (h->debug & 2)
            ccnr_debug_ccnb(h, __LINE__, "interest_expiry",
                            r_io_fdholder_from_fd(h, pe->filedesc),
                            pe->interest_msg, pe->size);
        r_match_consume_interest(h, pe);
        r_fwd_reap_needed(h, 0);
        return(0);        
    }
    if ((pe->flags & CCN_PR_STUFFED1) != 0) {
        pe->flags &= ~CCN_PR_STUFFED1;
        pe->flags |= CCN_PR_WAIT1;
        next_delay = special_delay = ev->evint;
    }
    else if (pe->outbound != NULL && pe->sent < pe->outbound->n) {
        unsigned filedesc = pe->outbound->buf[pe->sent];
        struct fdholder *fdholder = r_io_fdholder_from_fd(h, filedesc);
        if (fdholder != NULL && (fdholder->flags & CCN_FACE_NOSEND) == 0) {
            if (h->debug & 2)
                ccnr_debug_ccnb(h, __LINE__, "interest_to", fdholder,
                                pe->interest_msg, pe->size);
            pe->sent++;
            h->interests_sent += 1;
            h->interest_faceid = pe->filedesc;
            next_delay = nrand48(h->seed) % 8192 + 500;
            if (((pe->flags & CCN_PR_TAP) != 0) &&
                  ccn_indexbuf_member(nameprefix_for_pe(h, pe)->tap, pe->filedesc)) {
                next_delay = special_delay = 1;
            }
            else if ((pe->flags & CCN_PR_UNSENT) != 0) {
                pe->flags &= ~CCN_PR_UNSENT;
                pe->flags |= CCN_PR_WAIT1;
                next_delay = special_delay = ev->evint;
            }
            r_link_stuff_and_send(h, fdholder, pe->interest_msg, pe->size, NULL, 0);
            ccnr_meter_bump(h, fdholder->meter[FM_INTO], 1);
        }
        else
            ccn_indexbuf_remove_first_match(pe->outbound, filedesc);
    }
    /* The internal client may have already consumed the interest */
    if (pe->outbound == NULL)
        next_delay = CCN_INTEREST_LIFETIME_MICROSEC;
    else if (pe->sent == pe->outbound->n) {
        if (pe->usec <= CCN_INTEREST_LIFETIME_MICROSEC / 4)
            next_delay = CCN_INTEREST_LIFETIME_MICROSEC;
        else if (special_delay == 0)
            next_delay = CCN_INTEREST_LIFETIME_MICROSEC / 16;
        if (pe->fgen != h->forward_to_gen)
            replan_propagation(h, pe);
    }
    else {
        unsigned filedesc = pe->outbound->buf[pe->sent];
        struct fdholder *fdholder = r_io_fdholder_from_fd(h, filedesc);
        /* Wait longer before sending interest to ccnrc */
        if (fdholder != NULL && (fdholder->flags & CCN_FACE_DC) != 0)
            next_delay += 60000;
    }
    next_delay = pe_next_usec(h, pe, next_delay, __LINE__);
    return(next_delay);
}

/**
 * Adjust the outbound fdholder list for a new Interest, based upon
 * existing similar interests.
 * @result besides possibly updating the outbound set, returns
 *         an extra delay time before propagation.  A negative return value
 *         indicates the interest should be dropped.
 */
// XXX - rearrange to allow dummied-up "sent" entries.
// XXX - subtle point - when similar interests are present in the PIT, and a new dest appears due to prefix registration, only one of the set should get sent to the new dest.
static int
adjust_outbound_for_existing_interests(struct ccnr_handle *h, struct fdholder *fdholder,
                                       unsigned char *msg,
                                       struct ccn_parsed_interest *pi,
                                       struct nameprefix_entry *npe,
                                       struct ccn_indexbuf *outbound)
{
    struct propagating_entry *head = &npe->pe_head;
    struct propagating_entry *p;
    size_t presize = pi->offset[CCN_PI_B_Nonce];
    size_t postsize = pi->offset[CCN_PI_E] - pi->offset[CCN_PI_E_Nonce];
    size_t minsize = presize + postsize;
    unsigned char *post = msg + pi->offset[CCN_PI_E_Nonce];
    int k = 0;
    int max_redundant = 3; /* Allow this many dups from same fdholder */
    int i;
    int n;
    struct fdholder *otherface;
    int extra_delay = 0;

    if ((fdholder->flags & (CCN_FACE_MCAST | CCN_FACE_LINK)) != 0)
        max_redundant = 0;
    if (outbound != NULL) {
        for (p = head->next; p != head && outbound->n > 0; p = p->next) {
            if (p->size > minsize &&
                p->interest_msg != NULL &&
                p->usec > 0 &&
                0 == memcmp(msg, p->interest_msg, presize) &&
                0 == memcmp(post, p->interest_msg + p->size - postsize, postsize)) {
                /* Matches everything but the Nonce */
                otherface = r_io_fdholder_from_fd(h, p->filedesc);
                if (otherface == NULL)
                    continue;
                /*
                 * If scope is 2, we can't treat these as similar if
                 * they did not originate on the same host
                 */
                if (pi->scope == 2 &&
                    ((otherface->flags ^ fdholder->flags) & CCN_FACE_GG) != 0)
                    continue;
                if (h->debug & 32)
                    ccnr_debug_ccnb(h, __LINE__, "similar_interest",
                                    r_io_fdholder_from_fd(h, p->filedesc),
                                    p->interest_msg, p->size);
                if (fdholder->filedesc == p->filedesc) {
                    /*
                     * This is one we've already seen before from the same fdholder,
                     * but dropping it unconditionally would lose resiliency
                     * against dropped packets. Thus allow a few of them.
                     * Add some delay, though.
                     * XXX c.f. bug #13 // XXX - old bugid
                     */
                    extra_delay += npe->usec + 20000;
                    if ((++k) < max_redundant)
                        continue;
                    outbound->n = 0;
                    return(-1);
                }
                /*
                 * The existing interest from another fdholder will serve for us,
                 * but we still need to send this interest there or we
                 * could miss an answer from that direction. Note that
                 * interests from two other faces could conspire to cover
                 * this one completely as far as propagation is concerned,
                 * but it is still necessary to keep it around for the sake
                 * of returning content.
                 * This assumes a unicast link.  If there are multiple
                 * parties on this fdholder (broadcast or multicast), we
                 * do not want to send right away, because it is highly likely
                 * that we've seen an interest that one of the other parties
                 * is going to answer, and we'll see the answer, too.
                 */
                n = outbound->n;
                outbound->n = 0;
                for (i = 0; i < n; i++) {
                    if (p->filedesc == outbound->buf[i]) {
                        outbound->buf[0] = p->filedesc;
                        outbound->n = 1;
                        if ((otherface->flags & (CCN_FACE_MCAST | CCN_FACE_LINK)) != 0)
                            extra_delay += npe->usec + 10000;
                        break;
                    }
                }
                p->flags |= CCN_PR_EQV; /* Don't add new faces */
                // XXX - How robust is setting of CCN_PR_EQV?
                /*
                 * XXX - We would like to avoid having to keep this
                 * interest around if we get here with (outbound->n == 0).
                 * However, we still need to remember to send the content
                 * back to this fdholder, and the data structures are not
                 * there right now to represent this.  c.f. #100321.
                 */
            }
        }
    }
    return(extra_delay);
}

PUBLIC void
r_fwd_append_debug_nonce(struct ccnr_handle *h, struct fdholder *fdholder, struct ccn_charbuf *cb) {
        unsigned char s[12];
        int i;
        
        for (i = 0; i < 3; i++)
            s[i] = h->ccnr_id[i];
        s[i++] = h->logpid >> 8;
        s[i++] = h->logpid;
        s[i++] = fdholder->filedesc >> 8;
        s[i++] = fdholder->filedesc;
        s[i++] = h->sec;
        s[i++] = h->usec * 256 / 1000000;
        for (; i < sizeof(s); i++)
            s[i] = nrand48(h->seed);
        ccnb_append_tagged_blob(cb, CCN_DTAG_Nonce, s, i);
}

PUBLIC void
r_fwd_append_plain_nonce(struct ccnr_handle *h, struct fdholder *fdholder, struct ccn_charbuf *cb) {
        int noncebytes = 6;
        unsigned char *s = NULL;
        int i;
        
        ccn_charbuf_append_tt(cb, CCN_DTAG_Nonce, CCN_DTAG);
        ccn_charbuf_append_tt(cb, noncebytes, CCN_BLOB);
        s = ccn_charbuf_reserve(cb, noncebytes);
        for (i = 0; i < noncebytes; i++)
            s[i] = nrand48(h->seed) >> i;
        cb->length += noncebytes;
        ccn_charbuf_append_closer(cb);
}

/**
 * Schedules the propagation of an Interest message.
 */
PUBLIC int
r_fwd_propagate_interest(struct ccnr_handle *h,
                   struct fdholder *fdholder,
                   unsigned char *msg,
                   struct ccn_parsed_interest *pi,
                   struct nameprefix_entry *npe)
{
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    unsigned char *nonce;
    size_t noncesize;
    struct ccn_charbuf *cb = NULL;
    int res;
    struct propagating_entry *pe = NULL;
    unsigned char *msg_out = msg;
    size_t msg_out_size = pi->offset[CCN_PI_E];
    int usec;
    int ntap;
    int delaymask;
    int extra_delay = 0;
    struct ccn_indexbuf *outbound = NULL;
    intmax_t lifetime;
    
    lifetime = ccn_interest_lifetime(msg, pi);
    outbound = get_outbound_faces(h, fdholder, msg, pi, npe);
    if (outbound->n != 0) {
        extra_delay = adjust_outbound_for_existing_interests(h, fdholder, msg, pi, npe, outbound);
        if (extra_delay < 0) {
            /*
             * Completely subsumed by other interests.
             * We do not have to worry about generating a nonce if it
             * does not have one yet.
             */
            if (h->debug & 16)
                ccnr_debug_ccnb(h, __LINE__, "interest_subsumed", fdholder,
                                msg_out, msg_out_size);
            h->interests_dropped += 1;
            ccn_indexbuf_destroy(&outbound);
            return(0);
        }
    }
    if (pi->offset[CCN_PI_B_Nonce] == pi->offset[CCN_PI_E_Nonce]) {
        /* This interest has no nonce; add one before going on */
        size_t nonce_start = 0;
        cb = r_util_charbuf_obtain(h);
        ccn_charbuf_append(cb, msg, pi->offset[CCN_PI_B_Nonce]);
        nonce_start = cb->length;
        (h->appnonce)(h, fdholder, cb);
        noncesize = cb->length - nonce_start;
        ccn_charbuf_append(cb, msg + pi->offset[CCN_PI_B_OTHER],
                               pi->offset[CCN_PI_E] - pi->offset[CCN_PI_B_OTHER]);
        nonce = cb->buf + nonce_start;
        msg_out = cb->buf;
        msg_out_size = cb->length;
    }
    else {
        nonce = msg + pi->offset[CCN_PI_B_Nonce];
        noncesize = pi->offset[CCN_PI_E_Nonce] - pi->offset[CCN_PI_B_Nonce];
    }
    hashtb_start(h->propagating_tab, e);
    res = hashtb_seek(e, nonce, noncesize, 0);
    pe = e->data;
    if (pe != NULL && pe->interest_msg == NULL) {
        unsigned char *m;
        m = calloc(1, msg_out_size);
        if (m == NULL) {
            res = -1;
            pe = NULL;
            hashtb_delete(e);
        }
        else {
            memcpy(m, msg_out, msg_out_size);
            pe->interest_msg = m;
            pe->size = msg_out_size;
            pe->filedesc = fdholder->filedesc;
            fdholder->pending_interests += 1;
            if (lifetime < INT_MAX / (1000000 >> 6) * (4096 >> 6))
                pe->usec = lifetime * (1000000 >> 6) / (4096 >> 6);
            else
                pe->usec = INT_MAX;
            delaymask = 0xFFF;
            pe->sent = 0;            
            pe->outbound = outbound;
            pe->flags = 0;
            if (pi->scope == 0)
                pe->flags |= CCN_PR_SCOPE0;
            else if (pi->scope == 1)
                pe->flags |= CCN_PR_SCOPE1;
            else if (pi->scope == 2)
                pe->flags |= CCN_PR_SCOPE2;
            pe->fgen = h->forward_to_gen;
            link_propagating_interest_to_nameprefix(h, pe, npe);
            ntap = reorder_outbound_using_history(h, npe, pe);
            if (outbound->n > ntap &&
                  outbound->buf[ntap] == npe->src &&
                  extra_delay == 0) {
                pe->flags = CCN_PR_UNSENT;
                delaymask = 0xFF;
            }
            outbound = NULL;
            res = 0;
            if (ntap > 0)
                (usec = 1, pe->flags |= CCN_PR_TAP);
            else
                usec = (nrand48(h->seed) & delaymask) + 1 + extra_delay;
            usec = pe_next_usec(h, pe, usec, __LINE__);
            ccn_schedule_event(h->sched, usec, do_propagate, pe, npe->usec);
        }
    }
    else {
        ccnr_msg(h, "Interesting - this shouldn't happen much - ccnr.c:%d", __LINE__);
        /* We must have duplicated an existing nonce, or ENOMEM. */
        res = -1;
    }
    hashtb_end(e);
    if (cb != NULL)
        r_util_charbuf_release(h, cb);
    ccn_indexbuf_destroy(&outbound);
    return(res);
}

static struct nameprefix_entry *
nameprefix_for_pe(struct ccnr_handle *h, struct propagating_entry *pe)
{
    struct nameprefix_entry *npe;
    struct propagating_entry *p;
    
    /* If any significant time is spent here, a direct link is possible, but costs space. */
    for (p = pe->next; p->filedesc != CCN_NOFACEID; p = p->next)
        continue;
    npe = (void *)(((char *)p) - offsetof(struct nameprefix_entry, pe_head));
    return(npe);
}

static void
replan_propagation(struct ccnr_handle *h, struct propagating_entry *pe)
{
    struct nameprefix_entry *npe = NULL;
    struct ccn_indexbuf *x = pe->outbound;
    struct fdholder *fdholder = NULL;
    struct fdholder *from = NULL;
    int i;
    int k;
    int n;
    unsigned filedesc;
    unsigned checkmask = 0;
    unsigned wantmask = 0;
    
    pe->fgen = h->forward_to_gen;
    if ((pe->flags & (CCN_PR_SCOPE0 | CCN_PR_EQV)) != 0)
        return;
    from = r_io_fdholder_from_fd(h, pe->filedesc);
    if (from == NULL)
        return;
    npe = nameprefix_for_pe(h, pe);
    while (npe->parent != NULL && npe->forwarding == NULL)
        npe = npe->parent;
    if (npe->fgen != h->forward_to_gen)
        r_fwd_update_forward_to(h, npe);
    if (npe->forward_to == NULL || npe->forward_to->n == 0)
        return;
    if ((pe->flags & CCN_PR_SCOPE1) != 0)
        checkmask = CCN_FACE_GG;
    if ((pe->flags & CCN_PR_SCOPE2) != 0)
        checkmask = CCN_FACE_GG & ~(from->flags);
    if ((npe->flags & CCN_FORW_LOCAL) != 0)
        checkmask = ((from->flags & CCN_FACE_GG) != 0) ? CCN_FACE_GG : (~0);
    wantmask = checkmask;
    if (wantmask == CCN_FACE_GG)
        checkmask |= CCN_FACE_DC;
    for (n = npe->forward_to->n, i = 0; i < n; i++) {
        filedesc = npe->forward_to->buf[i];
        fdholder = r_io_fdholder_from_fd(h, filedesc);
        if (fdholder != NULL && filedesc != pe->filedesc &&
            ((fdholder->flags & checkmask) == wantmask)) {
            k = x->n;
            ccn_indexbuf_set_insert(x, filedesc);
            if (x->n > k && (h->debug & 32) != 0)
                ccnr_msg(h, "at %d adding %u", __LINE__, filedesc);
        }
    }
    // XXX - should account for similar interests, history, etc.
}

/**
 * Checks whether this Interest message has been seen before by using
 * its Nonce, recording it in the process.  Also, if it has been
 * seen and the original is still propagating, remove the fdholder that
 * the duplicate arrived on from the outbound set of the original.
 */
PUBLIC int
r_fwd_is_duplicate_flooded(struct ccnr_handle *h, unsigned char *msg,
                     struct ccn_parsed_interest *pi, unsigned filedesc)
{
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct propagating_entry *pe = NULL;
    int res;
    size_t nonce_start = pi->offset[CCN_PI_B_Nonce];
    size_t nonce_size = pi->offset[CCN_PI_E_Nonce] - nonce_start;
    if (nonce_size == 0)
        return(0);
    hashtb_start(h->propagating_tab, e);
    res = hashtb_seek(e, msg + nonce_start, nonce_size, 0);
    if (res == HT_OLD_ENTRY) {
        pe = e->data;
        if (promote_outbound(pe, filedesc) != -1)
            pe->sent++;
    }
    hashtb_end(e);
    return(res == HT_OLD_ENTRY);
}

/**
 * Finds the longest matching nameprefix, returns the component count or -1 for error.
 */
/* UNUSED */
PUBLIC int
r_fwd_nameprefix_longest_match(struct ccnr_handle *h, const unsigned char *msg,
                         struct ccn_indexbuf *comps, int ncomps)
{
    int i;
    int base;
    int answer = 0;
    struct nameprefix_entry *npe = NULL;

    if (ncomps + 1 > comps->n)
        return(-1);
    base = comps->buf[0];
    for (i = 0; i <= ncomps; i++) {
        npe = hashtb_lookup(h->nameprefix_tab, msg + base, comps->buf[i] - base);
        if (npe == NULL)
            break;
        answer = i;
        if (npe->children == 0)
            break;
    }
    ccnr_msg(h, "r_fwd_nameprefix_longest_match returning %d", answer);
    return(answer);
}

/**
 * Creates a nameprefix entry if it does not already exist, together
 * with all of its parents.
 */
PUBLIC int
r_fwd_nameprefix_seek(struct ccnr_handle *h, struct hashtb_enumerator *e,
                const unsigned char *msg, struct ccn_indexbuf *comps, int ncomps)
{
    int i;
    int base;
    int res = -1;
    struct nameprefix_entry *parent = NULL;
    struct nameprefix_entry *npe = NULL;
    struct propagating_entry *head = NULL;

    if (ncomps + 1 > comps->n)
        return(-1);
    base = comps->buf[0];
    for (i = 0; i <= ncomps; i++) {
        res = hashtb_seek(e, msg + base, comps->buf[i] - base, 0);
        if (res < 0)
            break;
        npe = e->data;
        if (res == HT_NEW_ENTRY) {
            head = &npe->pe_head;
            head->next = head;
            head->prev = head;
            head->filedesc = CCN_NOFACEID;
            npe->parent = parent;
            npe->forwarding = NULL;
            npe->fgen = h->forward_to_gen - 1;
            npe->forward_to = NULL;
            if (parent != NULL) {
                parent->children++;
                npe->flags = parent->flags;
                npe->src = parent->src;
                npe->osrc = parent->osrc;
                npe->usec = parent->usec;
            }
            else {
                npe->src = npe->osrc = CCN_NOFACEID;
                npe->usec = (nrand48(h->seed) % 4096U) + 8192;
            }
        }
        parent = npe;
    }
    return(res);
}
//EOF
///bin/cat << //EOF >> ccnr_store.c

PUBLIC struct content_entry *
r_store_next_child_at_level(struct ccnr_handle *h,
                    struct content_entry *content, int level)
{
    struct content_entry *next = NULL;
    struct ccn_charbuf *name;
    struct ccn_indexbuf *pred[CCN_SKIPLIST_MAX_DEPTH] = {NULL};
    int d;
    int res;
    
    if (content == NULL)
        return(NULL);
    if (content->ncomps <= level + 1)
        return(NULL);
    name = ccn_charbuf_create();
    ccn_name_init(name);
    res = ccn_name_append_components(name, content->key,
                                     content->comps[0],
                                     content->comps[level + 1]);
    if (res < 0) abort();
    res = ccn_name_next_sibling(name);
    if (res < 0) abort();
    if (h->debug & 8)
        ccnr_debug_ccnb(h, __LINE__, "child_successor", NULL,
                        name->buf, name->length);
    d = content_skiplist_findbefore(h, name->buf, name->length,
                                    NULL, pred);
    next = r_store_content_from_accession(h, pred[0]->buf[0]);
    if (next == content) {
        // XXX - I think this case should not occur, but just in case, avoid a loop.
        next = r_store_content_from_accession(h, r_store_content_skiplist_next(h, content));
        ccnr_debug_ccnb(h, __LINE__, "bump", NULL, next->key, next->size);
    }
    ccn_charbuf_destroy(&name);
    return(next);
}
//EOF
///bin/cat << //EOF >> ccnr_dispatch.c

static void
process_incoming_interest(struct ccnr_handle *h, struct fdholder *fdholder,
                          unsigned char *msg, size_t size)
{
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct ccn_parsed_interest parsed_interest = {0};
    struct ccn_parsed_interest *pi = &parsed_interest;
    size_t namesize = 0;
    int k;
    int res;
    int try;
    int matched;
    int s_ok;
    struct nameprefix_entry *npe = NULL;
    struct content_entry *content = NULL;
    struct content_entry *last_match = NULL;
    struct ccn_indexbuf *comps = r_util_indexbuf_obtain(h);
    if (size > 65535)
        res = -__LINE__;
    else
        res = ccn_parse_interest(msg, size, pi, comps);
    if (res < 0) {
        ccnr_msg(h, "error parsing Interest - code %d", res);
        ccn_indexbuf_destroy(&comps);
        return;
    }
    ccnr_meter_bump(h, fdholder->meter[FM_INTI], 1);
    if (pi->scope >= 0 && pi->scope < 2 &&
             (fdholder->flags & CCN_FACE_GG) == 0) {
        ccnr_debug_ccnb(h, __LINE__, "interest_outofscope", fdholder, msg, size);
        h->interests_dropped += 1;
    }
    else if (r_fwd_is_duplicate_flooded(h, msg, pi, fdholder->filedesc)) {
        if (h->debug & 16)
             ccnr_debug_ccnb(h, __LINE__, "interest_dup", fdholder, msg, size);
        h->interests_dropped += 1;
    }
    else {
        if (h->debug & (16 | 8 | 2))
            ccnr_debug_ccnb(h, __LINE__, "interest_from", fdholder, msg, size);
        if (h->debug & 16)
            ccnr_msg(h,
                     "version: %d, "
                     "prefix_comps: %d, "
                     "min_suffix_comps: %d, "
                     "max_suffix_comps: %d, "
                     "orderpref: %d, "
                     "answerfrom: %d, "
                     "scope: %d, "
                     "lifetime: %d.%04d, "
                     "excl: %d bytes, "
                     "etc: %d bytes",
                     pi->magic,
                     pi->prefix_comps,
                     pi->min_suffix_comps,
                     pi->max_suffix_comps,
                     pi->orderpref, pi->answerfrom, pi->scope,
                     ccn_interest_lifetime_seconds(msg, pi),
                     (int)(ccn_interest_lifetime(msg, pi) & 0xFFF) * 10000 / 4096,
                     pi->offset[CCN_PI_E_Exclude] - pi->offset[CCN_PI_B_Exclude],
                     pi->offset[CCN_PI_E_OTHER] - pi->offset[CCN_PI_B_OTHER]);
        if (pi->magic < 20090701) {
            if (++(h->oldformatinterests) == h->oldformatinterestgrumble) {
                h->oldformatinterestgrumble *= 2;
                ccnr_msg(h, "downrev interests received: %d (%d)",
                         h->oldformatinterests,
                         pi->magic);
            }
        }
        namesize = comps->buf[pi->prefix_comps] - comps->buf[0];
        h->interests_accepted += 1;
        s_ok = (pi->answerfrom & CCN_AOK_STALE) != 0;
        matched = 0;
        hashtb_start(h->nameprefix_tab, e);
        res = r_fwd_nameprefix_seek(h, e, msg, comps, pi->prefix_comps);
        npe = e->data;
        if (npe == NULL)
            goto Bail;
        if ((npe->flags & CCN_FORW_LOCAL) != 0 &&
            (fdholder->flags & CCN_FACE_GG) == 0) {
            ccnr_debug_ccnb(h, __LINE__, "interest_nonlocal", fdholder, msg, size);
            h->interests_dropped += 1;
            goto Bail;
        }
        if ((pi->answerfrom & CCN_AOK_CS) != 0) {
            last_match = NULL;
            content = r_store_find_first_match_candidate(h, msg, pi);
            if (content != NULL && (h->debug & 8))
                ccnr_debug_ccnb(h, __LINE__, "first_candidate", NULL,
                                content->key,
                                content->size);
            if (content != NULL &&
                !r_store_content_matches_interest_prefix(h, content, msg, comps,
                                                 pi->prefix_comps)) {
                if (h->debug & 8)
                    ccnr_debug_ccnb(h, __LINE__, "prefix_mismatch", NULL,
                                    msg, size);
                content = NULL;
            }
            for (try = 0; content != NULL; try++) {
                if ((s_ok || (content->flags & CCN_CONTENT_ENTRY_STALE) == 0) &&
                    ccn_content_matches_interest(content->key,
                                       content->size,
                                       0, NULL, msg, size, pi)) {
                    if ((pi->orderpref & 1) == 0 && // XXX - should be symbolic
                        pi->prefix_comps != comps->n - 1 &&
                        comps->n == content->ncomps &&
                        r_store_content_matches_interest_prefix(h, content, msg,
                                                        comps, comps->n - 1)) {
                        if (h->debug & 8)
                            ccnr_debug_ccnb(h, __LINE__, "skip_match", NULL,
                                            content->key,
                                            content->size);
                        goto move_along;
                    }
                    if (h->debug & 8)
                        ccnr_debug_ccnb(h, __LINE__, "matches", NULL,
                                        content->key,
                                        content->size);
                    if ((pi->orderpref & 1) == 0) // XXX - should be symbolic
                        break;
                    last_match = content;
                    content = r_store_next_child_at_level(h, content, comps->n - 1);
                    goto check_next_prefix;
                }
            move_along:
                content = r_store_content_from_accession(h, r_store_content_skiplist_next(h, content));
            check_next_prefix:
                if (content != NULL &&
                    !r_store_content_matches_interest_prefix(h, content, msg,
                                                     comps, pi->prefix_comps)) {
                    if (h->debug & 8)
                        ccnr_debug_ccnb(h, __LINE__, "prefix_mismatch", NULL,
                                        content->key,
                                        content->size);
                    content = NULL;
                }
            }
            if (last_match != NULL)
                content = last_match;
            if (content != NULL) {
                /* Check to see if we are planning to send already */
                enum cq_delay_class c;
                for (c = 0, k = -1; c < CCN_CQ_N && k == -1; c++)
                    if (fdholder->q[c] != NULL)
                        k = ccn_indexbuf_member(fdholder->q[c]->send_queue, content->accession);
                if (k == -1) {
                    k = r_sendq_face_send_queue_insert(h, fdholder, content);
                    if (k >= 0) {
                        if (h->debug & (32 | 8))
                            ccnr_debug_ccnb(h, __LINE__, "consume", fdholder, msg, size);
                    }
                    /* Any other matched interests need to be consumed, too. */
                    r_match_match_interests(h, content, NULL, fdholder, NULL);
                }
                if ((pi->answerfrom & CCN_AOK_EXPIRE) != 0)
                    r_store_mark_stale(h, content);
                matched = 1;
            }
        }
        if (!matched && pi->scope != 0 && npe != NULL)
            r_fwd_propagate_interest(h, fdholder, msg, pi, npe);
    Bail:
        hashtb_end(e);
    }
    r_util_indexbuf_release(h, comps);
}
//EOF
///bin/cat << //EOF >> ccnr_store.c

/**
 * Mark content as stale
 */
PUBLIC void
r_store_mark_stale(struct ccnr_handle *h, struct content_entry *content)
{
    ccn_accession_t accession = content->accession;
    if ((content->flags & CCN_CONTENT_ENTRY_STALE) != 0)
        return;
    if (h->debug & 4)
            ccnr_debug_ccnb(h, __LINE__, "stale", NULL,
                            content->key, content->size);
    content->flags |= CCN_CONTENT_ENTRY_STALE;
    h->n_stale++;
    if (accession < h->min_stale)
        h->min_stale = accession;
    if (accession > h->max_stale)
        h->max_stale = accession;
}

/**
 * Scheduled event that makes content stale when its FreshnessSeconds
 * has exported.
 *
 * May actually remove the content if we are over quota.
 */
static int
expire_content(struct ccn_schedule *sched,
               void *clienth,
               struct ccn_scheduled_event *ev,
               int flags)
{
    struct ccnr_handle *h = clienth;
    ccn_accession_t accession = ev->evint;
    struct content_entry *content = NULL;
    int res;
    unsigned n;
    if ((flags & CCN_SCHEDULE_CANCEL) != 0)
        return(0);
    content = r_store_content_from_accession(h, accession);
    if (content != NULL) {
        n = hashtb_n(h->content_tab);
        /* The fancy test here lets existing stale content go away, too. */
        if ((n - (n >> 3)) > h->capacity ||
            (n > h->capacity && h->min_stale > h->max_stale)) {
            res = r_store_remove_content(h, content);
            if (res == 0)
                return(0);
        }
        r_store_mark_stale(h, content);
    }
    return(0);
}

/**
 * Schedules content expiration based on its FreshnessSeconds.
 *
 */
PUBLIC void
r_store_set_content_timer(struct ccnr_handle *h, struct content_entry *content,
                  struct ccn_parsed_ContentObject *pco)
{
    int seconds = 0;
    int microseconds = 0;
    size_t start = pco->offset[CCN_PCO_B_FreshnessSeconds];
    size_t stop  = pco->offset[CCN_PCO_E_FreshnessSeconds];
    if (start == stop)
        return;
    seconds = ccn_fetch_tagged_nonNegativeInteger(
                CCN_DTAG_FreshnessSeconds,
                content->key,
                start, stop);
    if (seconds <= 0)
        return;
    if (seconds > ((1U<<31) / 1000000)) {
        ccnr_debug_ccnb(h, __LINE__, "FreshnessSeconds_too_large", NULL,
            content->key, pco->offset[CCN_PCO_E]);
        return;
    }
    microseconds = seconds * 1000000;
    ccn_schedule_event(h->sched, microseconds,
                       &expire_content, NULL, content->accession);
}
//EOF
///bin/cat << //EOF >> ccnr_dispatch.c

static void
process_incoming_content(struct ccnr_handle *h, struct fdholder *fdholder,
                         unsigned char *wire_msg, size_t wire_size)
{
    unsigned char *msg;
    size_t size;
    struct hashtb_enumerator ee;
    struct hashtb_enumerator *e = &ee;
    struct ccn_parsed_ContentObject obj = {0};
    int res;
    size_t keysize = 0;
    size_t tailsize = 0;
    unsigned char *tail = NULL;
    struct content_entry *content = NULL;
    int i;
    struct ccn_indexbuf *comps = r_util_indexbuf_obtain(h);
    struct ccn_charbuf *cb = r_util_charbuf_obtain(h);
    
    msg = wire_msg;
    size = wire_size;
    
    res = ccn_parse_ContentObject(msg, size, &obj, comps);
    if (res < 0) {
        ccnr_msg(h, "error parsing ContentObject - code %d", res);
        goto Bail;
    }
    ccnr_meter_bump(h, fdholder->meter[FM_DATI], 1);
    if (comps->n < 1 ||
        (keysize = comps->buf[comps->n - 1]) > 65535 - 36) {
        ccnr_msg(h, "ContentObject with keysize %lu discarded",
                 (unsigned long)keysize);
        ccnr_debug_ccnb(h, __LINE__, "oversize", fdholder, msg, size);
        res = -__LINE__;
        goto Bail;
    }
    /* Make the ContentObject-digest name component explicit */
    ccn_digest_ContentObject(msg, &obj);
    if (obj.digest_bytes != 32) {
        ccnr_debug_ccnb(h, __LINE__, "indigestible", fdholder, msg, size);
        goto Bail;
    }
    i = comps->buf[comps->n - 1];
    ccn_charbuf_append(cb, msg, i);
    ccn_charbuf_append_tt(cb, CCN_DTAG_Component, CCN_DTAG);
    ccn_charbuf_append_tt(cb, obj.digest_bytes, CCN_BLOB);
    ccn_charbuf_append(cb, obj.digest, obj.digest_bytes);
    ccn_charbuf_append_closer(cb);
    ccn_charbuf_append(cb, msg + i, size - i);
    msg = cb->buf;
    size = cb->length;
    res = ccn_parse_ContentObject(msg, size, &obj, comps);
    if (res < 0) abort(); /* must have just messed up */
    
    if (obj.magic != 20090415) {
        if (++(h->oldformatcontent) == h->oldformatcontentgrumble) {
            h->oldformatcontentgrumble *= 10;
            ccnr_msg(h, "downrev content items received: %d (%d)",
                     h->oldformatcontent,
                     obj.magic);
        }
    }
    if (h->debug & 4)
        ccnr_debug_ccnb(h, __LINE__, "content_from", fdholder, msg, size);
    keysize = obj.offset[CCN_PCO_B_Content];
    tail = msg + keysize;
    tailsize = size - keysize;
    hashtb_start(h->content_tab, e);
    res = hashtb_seek(e, msg, keysize, tailsize);
    content = e->data;
    if (res == HT_OLD_ENTRY) {
        if (tailsize != e->extsize ||
              0 != memcmp(tail, ((unsigned char *)e->key) + keysize, tailsize)) {
            ccnr_msg(h, "ContentObject name collision!!!!!");
            ccnr_debug_ccnb(h, __LINE__, "new", fdholder, msg, size);
            ccnr_debug_ccnb(h, __LINE__, "old", NULL, e->key, e->keysize + e->extsize);
            content = NULL;
            hashtb_delete(e); /* XXX - Mercilessly throw away both of them. */
            res = -__LINE__;
        }
        else if ((content->flags & CCN_CONTENT_ENTRY_STALE) != 0) {
            /* When old content arrives after it has gone stale, freshen it */
            // XXX - ought to do mischief checks before this
            content->flags &= ~CCN_CONTENT_ENTRY_STALE;
            h->n_stale--;
            r_store_set_content_timer(h, content, &obj);
            // XXX - no counter for this case
        }
        else {
            h->content_dups_recvd++;
            ccnr_msg(h, "received duplicate ContentObject from %u (accession %llu)",
                     fdholder->filedesc, (unsigned long long)content->accession);
            ccnr_debug_ccnb(h, __LINE__, "dup", fdholder, msg, size);
        }
    }
    else if (res == HT_NEW_ENTRY) {
        content->accession = ++(h->accession);
        r_store_enroll_content(h, content);
        if (content == r_store_content_from_accession(h, content->accession)) {
            content->ncomps = comps->n;
            content->comps = calloc(comps->n, sizeof(comps[0]));
        }
        content->key_size = e->keysize;
        content->size = e->keysize + e->extsize;
        content->key = e->key;
        if (content->comps != NULL) {
            for (i = 0; i < comps->n; i++)
                content->comps[i] = comps->buf[i];
            r_store_content_skiplist_insert(h, content);
            r_store_set_content_timer(h, content, &obj);
        }
        else {
            ccnr_msg(h, "could not enroll ContentObject (accession %llu)",
                (unsigned long long)content->accession);
            hashtb_delete(e);
            res = -__LINE__;
            content = NULL;
        }
        /* Mark public keys supplied at startup as precious. */
        if (obj.type == CCN_CONTENT_KEY && content->accession <= (h->capacity + 7)/8)
            content->flags |= CCN_CONTENT_ENTRY_PRECIOUS;
    }
    hashtb_end(e);
Bail:
    r_util_indexbuf_release(h, comps);
    r_util_charbuf_release(h, cb);
    cb = NULL;
    if (res >= 0 && content != NULL) {
        int n_matches;
        enum cq_delay_class c;
        struct content_queue *q;
        n_matches = r_match_match_interests(h, content, &obj, NULL, fdholder);
        if (res == HT_NEW_ENTRY) {
            if (n_matches < 0) {
                r_store_remove_content(h, content);
                return;
            }
            if (n_matches == 0 && (fdholder->flags & CCN_FACE_GG) == 0) {
                content->flags |= CCN_CONTENT_ENTRY_SLOWSEND;
                ccn_indexbuf_append_element(h->unsol, content->accession);
            }
        }
        for (c = 0; c < CCN_CQ_N; c++) {
            q = fdholder->q[c];
            if (q != NULL) {
                i = ccn_indexbuf_member(q->send_queue, content->accession);
                if (i >= 0) {
                    /*
                     * In the case this consumed any interests from this source,
                     * don't send the content back
                     */
                    if (h->debug & 8)
                        ccnr_debug_ccnb(h, __LINE__, "content_nosend", fdholder, msg, size);
                    q->send_queue->buf[i] = 0;
                }
            }
        }
    }
}

static void
process_input_message(struct ccnr_handle *h, struct fdholder *fdholder,
                      unsigned char *msg, size_t size, int pdu_ok)
{
    struct ccn_skeleton_decoder decoder = {0};
    struct ccn_skeleton_decoder *d = &decoder;
    ssize_t dres;
    enum ccn_dtag dtag;
    
    if ((fdholder->flags & CCN_FACE_UNDECIDED) != 0) {
        fdholder->flags &= ~CCN_FACE_UNDECIDED;
        if ((fdholder->flags & CCN_FACE_LOOPBACK) != 0)
            fdholder->flags |= CCN_FACE_GG;
        /* YYY This is the first place that we know that an inbound stream fdholder is speaking CCNx protocol. */
        r_io_register_new_face(h, fdholder);
    }
    d->state |= CCN_DSTATE_PAUSE;
    dres = ccn_skeleton_decode(d, msg, size);
    if (d->state < 0)
        abort(); /* cannot happen because of checks in caller */
    if (CCN_GET_TT_FROM_DSTATE(d->state) != CCN_DTAG) {
        ccnr_msg(h, "discarding unknown message; size = %lu", (unsigned long)size);
        // XXX - keep a count?
        return;
    }
    dtag = d->numval;
    switch (dtag) {
        case CCN_DTAG_CCNProtocolDataUnit:
            if (!pdu_ok)
                break;
            size -= d->index;
            if (size > 0)
                size--;
            msg += d->index;
            fdholder->flags |= CCN_FACE_LINK;
            fdholder->flags &= ~CCN_FACE_GG;
            memset(d, 0, sizeof(*d));
            while (d->index < size) {
                dres = ccn_skeleton_decode(d, msg + d->index, size - d->index);
                if (d->state != 0)
                    abort(); /* cannot happen because of checks in caller */
                /* The pdu_ok parameter limits the recursion depth */
                process_input_message(h, fdholder, msg + d->index - dres, dres, 0);
            }
            return;
        case CCN_DTAG_Interest:
            process_incoming_interest(h, fdholder, msg, size);
            return;
        case CCN_DTAG_ContentObject:
            process_incoming_content(h, fdholder, msg, size);
            return;
        case CCN_DTAG_SequenceNumber:
            r_link_process_incoming_link_message(h, fdholder, dtag, msg, size);
            return;
        default:
            break;
    }
    ccnr_msg(h, "discarding unknown message; dtag=%u, size = %lu",
             (unsigned)dtag,
             (unsigned long)size);
}

/**
 * Break up data in a face's input buffer buffer into individual messages,
 * and call process_input_message on each one.
 *
 * This is used to handle things originating from the internal client -
 * its output is input for fdholder 0.
 */
static void
process_input_buffer(struct ccnr_handle *h, struct fdholder *fdholder)
{
    unsigned char *msg;
    size_t size;
    ssize_t dres;
    struct ccn_skeleton_decoder *d;

    if (fdholder == NULL || fdholder->inbuf == NULL)
        return;
    d = &fdholder->decoder;
    msg = fdholder->inbuf->buf;
    size = fdholder->inbuf->length;
    while (d->index < size) {
        dres = ccn_skeleton_decode(d, msg + d->index, size - d->index);
        if (d->state != 0)
            break;
        process_input_message(h, fdholder, msg + d->index - dres, dres, 0);
    }
    if (d->index != size) {
        ccnr_msg(h, "protocol error on fdholder %u (state %d), discarding %d bytes",
                     fdholder->filedesc, d->state, (int)(size - d->index));
        // XXX - perhaps this should be a fatal error.
    }
    fdholder->inbuf->length = 0;
    memset(d, 0, sizeof(*d));
}

/**
 * Process the input from a socket.
 *
 * The socket has been found ready for input by the poll call.
 * Decide what fdholder it corresponds to, and after checking for exceptional
 * cases, receive data, parse it into ccnb-encoded messages, and call
 * process_input_message for each one.
 */
static void
process_input(struct ccnr_handle *h, int fd)
{
    struct fdholder *fdholder = NULL;
    struct fdholder *source = NULL;
    ssize_t res;
    ssize_t dres;
    ssize_t msgstart;
    unsigned char *buf;
    struct ccn_skeleton_decoder *d;
    struct sockaddr_storage sstor;
    socklen_t addrlen = sizeof(sstor);
    struct sockaddr *addr = (struct sockaddr *)&sstor;
    int err = 0;
    socklen_t err_sz;
    
    fdholder = r_io_fdholder_from_fd(h, fd);
    if (fdholder == NULL)
        return;
    if ((fdholder->flags & (CCN_FACE_DGRAM | CCN_FACE_PASSIVE)) == CCN_FACE_PASSIVE) {
        r_io_accept_connection(h, fd);
        return;
    }
    err_sz = sizeof(err);
    res = getsockopt(fdholder->recv_fd, SOL_SOCKET, SO_ERROR, &err, &err_sz);
    if (res >= 0 && err != 0) {
        ccnr_msg(h, "error on fdholder %u: %s (%d)", fdholder->filedesc, strerror(err), err);
        if (err == ETIMEDOUT && (fdholder->flags & CCN_FACE_CONNECTING) != 0) {
            r_io_shutdown_client_fd(h, fd);
            return;
        }
    }
    d = &fdholder->decoder;
    if (fdholder->inbuf == NULL)
        fdholder->inbuf = ccn_charbuf_create();
    if (fdholder->inbuf->length == 0)
        memset(d, 0, sizeof(*d));
    buf = ccn_charbuf_reserve(fdholder->inbuf, 8800);
    memset(&sstor, 0, sizeof(sstor));
    res = recvfrom(fdholder->recv_fd, buf, fdholder->inbuf->limit - fdholder->inbuf->length,
            /* flags */ 0, addr, &addrlen);
    if (res == -1)
        ccnr_msg(h, "recvfrom fdholder %u :%s (errno = %d)",
                    fdholder->filedesc, strerror(errno), errno);
    else if (res == 0 && (fdholder->flags & CCN_FACE_DGRAM) == 0)
        r_io_shutdown_client_fd(h, fd);
    else {
        source = fdholder;
        ccnr_meter_bump(h, source->meter[FM_BYTI], res);
        source->recvcount++;
        source->surplus = 0; // XXX - we don't actually use this, except for some obscure messages.
        if (res <= 1 && (source->flags & CCN_FACE_DGRAM) != 0) {
            // XXX - If the initial heartbeat gets missed, we don't realize the locality of the fdholder.
            if (h->debug & 128)
                ccnr_msg(h, "%d-byte heartbeat on %d", (int)res, source->filedesc);
            return;
        }
        fdholder->inbuf->length += res;
        msgstart = 0;
        if (((fdholder->flags & CCN_FACE_UNDECIDED) != 0 &&
             fdholder->inbuf->length >= 6 &&
             0 == memcmp(fdholder->inbuf->buf, "GET ", 4))) {
            ccnr_stats_handle_http_connection(h, fdholder);
            return;
        }
        dres = ccn_skeleton_decode(d, buf, res);
        while (d->state == 0) {
            process_input_message(h, source,
                                  fdholder->inbuf->buf + msgstart,
                                  d->index - msgstart,
                                  (fdholder->flags & CCN_FACE_LOCAL) != 0);
            msgstart = d->index;
            if (msgstart == fdholder->inbuf->length) {
                fdholder->inbuf->length = 0;
                return;
            }
            dres = ccn_skeleton_decode(d,
                    fdholder->inbuf->buf + d->index, // XXX - msgstart and d->index are the same here - use msgstart
                    res = fdholder->inbuf->length - d->index);  // XXX - why is res set here?
        }
        if ((fdholder->flags & CCN_FACE_DGRAM) != 0) {
            ccnr_msg(h, "protocol error on fdholder %u, discarding %u bytes",
                source->filedesc,
                (unsigned)(fdholder->inbuf->length));  // XXX - Should be fdholder->inbuf->length - d->index (or msgstart)
            fdholder->inbuf->length = 0;
            /* XXX - should probably ignore this source for a while */
            return;
        }
        else if (d->state < 0) {
            ccnr_msg(h, "protocol error on fdholder %u", source->filedesc);
            r_io_shutdown_client_fd(h, fd);
            return;
        }
        if (msgstart < fdholder->inbuf->length && msgstart > 0) {
            /* move partial message to start of buffer */
            memmove(fdholder->inbuf->buf, fdholder->inbuf->buf + msgstart,
                fdholder->inbuf->length - msgstart);
            fdholder->inbuf->length -= msgstart;
            d->index -= msgstart;
        }
    }
}

PUBLIC void
r_dispatch_process_internal_client_buffer(struct ccnr_handle *h)
{
    struct fdholder *fdholder = h->face0;
    if (fdholder == NULL)
        return;
    fdholder->inbuf = ccn_grab_buffered_output(h->internal_client);
    if (fdholder->inbuf == NULL)
        return;
    ccnr_meter_bump(h, fdholder->meter[FM_BYTI], fdholder->inbuf->length);
    process_input_buffer(h, fdholder);
    ccn_charbuf_destroy(&(fdholder->inbuf));
}
//EOF
///bin/cat << //EOF >> ccnr_io.c

/**
 * Handle errors after send() or sendto().
 * @returns -1 if error has been dealt with, or 0 to defer sending.
 */
static int
handle_send_error(struct ccnr_handle *h, int errnum, struct fdholder *fdholder,
                  const void *data, size_t size)
{
    int res = -1;
    if (errnum == EAGAIN) {
        res = 0;
    }
    else if (errnum == EPIPE) {
        fdholder->flags |= CCN_FACE_NOSEND;
        fdholder->outbufindex = 0;
        ccn_charbuf_destroy(&fdholder->outbuf);
    }
    else {
        ccnr_msg(h, "send to fd %u failed: %s (errno = %d)",
                 fdholder->filedesc, strerror(errnum), errnum);
        if (errnum == EISCONN)
            res = 0;
    }
    return(res);
}

static int
sending_fd(struct ccnr_handle *h, struct fdholder *fdholder)
{
    return(fdholder->filedesc);
}

/**
 * Send data to the fdholder.
 *
 * No direct error result is provided; the fdholder state is updated as needed.
 */
PUBLIC void
r_io_send(struct ccnr_handle *h,
          struct fdholder *fdholder,
          const void *data, size_t size)
{
    ssize_t res;
    if ((fdholder->flags & CCN_FACE_NOSEND) != 0)
        return;
    fdholder->surplus++;
    if (fdholder->outbuf != NULL) {
        ccn_charbuf_append(fdholder->outbuf, data, size);
        return;
    }
    if (fdholder == h->face0) {
        ccnr_meter_bump(h, fdholder->meter[FM_BYTO], size);
        ccn_dispatch_message(h->internal_client, (void *)data, size);
        r_dispatch_process_internal_client_buffer(h);
        return;
    }
    if ((fdholder->flags & CCN_FACE_DGRAM) == 0)
        res = send(fdholder->recv_fd, data, size, 0);
    else
        res = sendto(sending_fd(h, fdholder), data, size, 0,
                     fdholder->addr, fdholder->addrlen);
    if (res > 0)
        ccnr_meter_bump(h, fdholder->meter[FM_BYTO], res);
    if (res == size)
        return;
    if (res == -1) {
        res = handle_send_error(h, errno, fdholder, data, size);
        if (res == -1)
            return;
    }
    if ((fdholder->flags & CCN_FACE_DGRAM) != 0) {
        ccnr_msg(h, "sendto short");
        return;
    }
    fdholder->outbufindex = 0;
    fdholder->outbuf = ccn_charbuf_create();
    if (fdholder->outbuf == NULL) {
        ccnr_msg(h, "do_write: %s", strerror(errno));
        return;
    }
    ccn_charbuf_append(fdholder->outbuf,
                       ((const unsigned char *)data) + res, size - res);
}
//EOF
///bin/cat << //EOF >> ccnr_link.c
PUBLIC void
r_link_do_deferred_write(struct ccnr_handle *h, int fd)
{
    /* This only happens on connected sockets */
    ssize_t res;
    struct fdholder *fdholder = r_io_fdholder_from_fd(h, fd);
    if (fdholder == NULL)
        return;
    if (fdholder->outbuf != NULL) {
        ssize_t sendlen = fdholder->outbuf->length - fdholder->outbufindex;
        if (sendlen > 0) {
            res = send(fd, fdholder->outbuf->buf + fdholder->outbufindex, sendlen, 0);
            if (res == -1) {
                if (errno == EPIPE) {
                    fdholder->flags |= CCN_FACE_NOSEND;
                    fdholder->outbufindex = 0;
                    ccn_charbuf_destroy(&fdholder->outbuf);
                    return;
                }
                ccnr_msg(h, "send: %s (errno = %d)", strerror(errno), errno);
                r_io_shutdown_client_fd(h, fd);
                return;
            }
            if (res == sendlen) {
                fdholder->outbufindex = 0;
                ccn_charbuf_destroy(&fdholder->outbuf);
                if ((fdholder->flags & CCN_FACE_CLOSING) != 0)
                    r_io_shutdown_client_fd(h, fd);
                return;
            }
            fdholder->outbufindex += res;
            return;
        }
        fdholder->outbufindex = 0;
        ccn_charbuf_destroy(&fdholder->outbuf);
    }
    if ((fdholder->flags & CCN_FACE_CLOSING) != 0)
        r_io_shutdown_client_fd(h, fd);
    else if ((fdholder->flags & CCN_FACE_CONNECTING) != 0) {
        fdholder->flags &= ~CCN_FACE_CONNECTING;
        ccnr_face_status_change(h, fdholder->filedesc);
    }
    else
        ccnr_msg(h, "ccnr:r_link_do_deferred_write: something fishy on %d", fd);
}
//EOF
///bin/cat << //EOF >> ccnr_io.c
/**
 * Set up the array of fd descriptors for the poll(2) call.
 *
 */
PUBLIC void
r_io_prepare_poll_fds(struct ccnr_handle *h)
{
    int i, j, nfds;
    
    for (i = 0, nfds = 0; i < h->face_limit; i++)
        if (r_io_fdholder_from_fd(h, i) != NULL)
            nfds++;
    
    if (nfds != h->nfds) {
        h->nfds = nfds;
        h->fds = realloc(h->fds, h->nfds * sizeof(h->fds[0]));
        memset(h->fds, 0, h->nfds * sizeof(h->fds[0]));
    }
    for (i = 0, j = 0; i < h->face_limit; i++) {
        struct fdholder *fdholder = r_io_fdholder_from_fd(h, i);
        if (fdholder != NULL) {
            h->fds[j].fd = fdholder->filedesc;
            h->fds[j].events = ((fdholder->flags & CCN_FACE_NORECV) == 0) ? POLLIN : 0;
            if ((fdholder->outbuf != NULL || (fdholder->flags & CCN_FACE_CLOSING) != 0))
                h->fds[j].events |= POLLOUT;
            j++;
        }
    }
}
//EOF
///bin/cat << //EOF >> ccnr_dispatch.c
/**
 * Run the main loop of the ccnr
 */
PUBLIC void
r_dispatch_run(struct ccnr_handle *h)
{
    int i;
    int res;
    int timeout_ms = -1;
    int prev_timeout_ms = -1;
    int usec;
    for (h->running = 1; h->running;) {
        r_dispatch_process_internal_client_buffer(h);
        usec = ccn_schedule_run(h->sched);
        timeout_ms = (usec < 0) ? -1 : ((usec + 960) / 1000);
        if (timeout_ms == 0 && prev_timeout_ms == 0)
            timeout_ms = 1;
        r_dispatch_process_internal_client_buffer(h);
        r_io_prepare_poll_fds(h);
        if (0) ccnr_msg(h, "at ccnr.c:%d poll(h->fds, %d, %d)", __LINE__, h->nfds, timeout_ms);
        res = poll(h->fds, h->nfds, timeout_ms);
        prev_timeout_ms = ((res == 0) ? timeout_ms : 1);
        if (-1 == res) {
            ccnr_msg(h, "poll: %s (errno = %d)", strerror(errno), errno);
            sleep(1);
            continue;
        }
        for (i = 0; res > 0 && i < h->nfds; i++) {
            if (h->fds[i].revents != 0) {
                res--;
                if (h->fds[i].revents & (POLLERR | POLLNVAL | POLLHUP)) {
                    if (h->fds[i].revents & (POLLIN))
                        process_input(h, h->fds[i].fd);
                    else
                        r_io_shutdown_client_fd(h, h->fds[i].fd);
                    continue;
                }
                if (h->fds[i].revents & (POLLOUT))
                    r_link_do_deferred_write(h, h->fds[i].fd);
                else if (h->fds[i].revents & (POLLIN))
                    process_input(h, h->fds[i].fd);
            }
        }
    }
}
//EOF
///bin/cat << //EOF >> ccnr_util.c

PUBLIC void
r_util_reseed(struct ccnr_handle *h)
{
    int fd;
    ssize_t res;
    
    res = -1;
    fd = open("/dev/urandom", O_RDONLY);
    if (fd != -1) {
        res = read(fd, h->seed, sizeof(h->seed));
        close(fd);
    }
    if (res != sizeof(h->seed)) {
        h->seed[1] = (unsigned short)getpid(); /* better than no entropy */
        h->seed[2] = (unsigned short)time(NULL);
    }
    /*
     * The call to seed48 is needed by cygwin, and should be harmless
     * on other platforms.
     */
    seed48(h->seed);
}
//EOF
///bin/cat << //EOF >> ccnr_net.c

PUBLIC char *
r_net_get_local_sockname(void)
{
    struct sockaddr_un sa;
    ccn_setup_sockaddr_un(NULL, &sa);
    return(strdup(sa.sun_path));
}
//EOF
///bin/cat << //EOF >> ccnr_util.c

PUBLIC void
r_util_gettime(const struct ccn_gettime *self, struct ccn_timeval *result)
{
    struct ccnr_handle *h = self->data;
    struct timeval now = {0};
    gettimeofday(&now, 0);
    result->s = now.tv_sec;
    result->micros = now.tv_usec;
    h->sec = now.tv_sec;
    h->usec = now.tv_usec;
}
//EOF
///bin/cat << //EOF >> ccnr_net.c

PUBLIC void
r_net_setsockopt_v6only(struct ccnr_handle *h, int fd)
{
    int yes = 1;
    int res = 0;
#ifdef IPV6_V6ONLY
    res = setsockopt(fd, IPPROTO_IPV6, IPV6_V6ONLY, &yes, sizeof(yes));
#endif
    if (res == -1)
        ccnr_msg(h, "warning - could not set IPV6_V6ONLY on fd %d: %s",
                 fd, strerror(errno));
}

static const char *
af_name(int family)
{
    switch (family) {
        case AF_INET:
            return("ipv4");
        case AF_INET6:
            return("ipv6");
        default:
            return("");
    }
}

PUBLIC int
r_net_listen_on_wildcards(struct ccnr_handle *h)
{
    int fd;
    int res;
    int whichpf;
    struct addrinfo hints = {0};
    struct addrinfo *addrinfo = NULL;
    struct addrinfo *a;
    
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    for (whichpf = 0; whichpf < 2; whichpf++) {
        hints.ai_family = whichpf ? PF_INET6 : PF_INET;
        res = getaddrinfo(NULL, h->portstr, &hints, &addrinfo);
        if (res == 0) {
            for (a = addrinfo; a != NULL; a = a->ai_next) {
                fd = socket(a->ai_family, SOCK_STREAM, 0);
                if (fd != -1) {
                    int yes = 1;
                    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
                    if (a->ai_family == AF_INET6)
                        r_net_setsockopt_v6only(h, fd);
                    res = bind(fd, a->ai_addr, a->ai_addrlen);
                    if (res != 0) {
                        close(fd);
                        continue;
                    }
                    res = listen(fd, 30);
                    if (res == -1) {
                        close(fd);
                        continue;
                    }
                    r_io_record_connection(h, fd,
                                      a->ai_addr, a->ai_addrlen,
                                      CCN_FACE_PASSIVE);
                    ccnr_msg(h, "accepting %s connections on fd %d",
                             af_name(a->ai_family), fd);
                }
            }
            freeaddrinfo(addrinfo);
        }
    }
    return(0);
}

PUBLIC int
r_net_listen_on_address(struct ccnr_handle *h, const char *addr)
{
    int fd;
    int res;
    struct addrinfo hints = {0};
    struct addrinfo *addrinfo = NULL;
    struct addrinfo *a;
    int ok = 0;
    
    ccnr_msg(h, "listen_on %s", addr);
    hints.ai_socktype = SOCK_DGRAM;
    hints.ai_flags = AI_PASSIVE;
    res = getaddrinfo(addr, h->portstr, &hints, &addrinfo);
    if (res == 0) {
        for (a = addrinfo; a != NULL; a = a->ai_next) {
            fd = socket(a->ai_family, SOCK_STREAM, 0);
            if (fd != -1) {
                int yes = 1;
                setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
                if (a->ai_family == AF_INET6)
                    r_net_setsockopt_v6only(h, fd);
                res = bind(fd, a->ai_addr, a->ai_addrlen);
                if (res != 0) {
                    close(fd);
                    continue;
                }
                res = listen(fd, 30);
                if (res == -1) {
                    close(fd);
                    continue;
                }
                r_io_record_connection(h, fd,
                                  a->ai_addr, a->ai_addrlen,
                                  CCN_FACE_PASSIVE);
                ccnr_msg(h, "accepting %s connections on fd %d",
                         af_name(a->ai_family), fd);
                ok++;
            }
        }
        freeaddrinfo(addrinfo);
    }
    return(ok > 0 ? 0 : -1);
}

PUBLIC int
r_net_listen_on(struct ccnr_handle *h, const char *addrs)
{
    unsigned char ch;
    unsigned char dlm;
    int res = 0;
    int i;
    struct ccn_charbuf *addr = NULL;
    
    if (addrs == NULL || !*addrs || 0 == strcmp(addrs, "*"))
        return(r_net_listen_on_wildcards(h));
    addr = ccn_charbuf_create();
    for (i = 0, ch = addrs[i]; addrs[i] != 0;) {
        addr->length = 0;
        dlm = 0;
        if (ch == '[') {
            dlm = ']';
            ch = addrs[++i];
        }
        for (; ch > ' ' && ch != ',' && ch != ';' && ch != dlm; ch = addrs[++i])
            ccn_charbuf_append_value(addr, ch, 1);
        if (ch && ch == dlm)
            ch = addrs[++i];
        if (addr->length > 0) {
            res |= r_net_listen_on_address(h, ccn_charbuf_as_string(addr));
        }
        while ((0 < ch && ch <= ' ') || ch == ',' || ch == ';')
            ch = addrs[++i];
    }
    ccn_charbuf_destroy(&addr);
    return(res);
}
//EOF
///bin/cat << //EOF >> ccnr_init.c

/**
 * Start a new ccnr instance
 * @param progname - name of program binary, used for locating helpers
 * @param logger - logger function
 * @param loggerdata - data to pass to logger function
 */
PUBLIC struct ccnr_handle *
r_init_create(const char *progname, ccnr_logger logger, void *loggerdata)
{
    char *sockname;
    // const char *portstr;
    const char *debugstr;
    const char *entrylimit;
    const char *listen_on;
    struct ccnr_handle *h;
    struct hashtb_param param = {0};
    
    sockname = r_net_get_local_sockname();
    h = calloc(1, sizeof(*h));
    if (h == NULL)
        return(h);
    h->logger = logger;
    h->loggerdata = loggerdata;
    h->appnonce = &r_fwd_append_plain_nonce;
    h->logpid = (int)getpid();
    h->progname = progname;
    h->debug = -1;
    h->skiplinks = ccn_indexbuf_create();
    param.finalize_data = h;
    h->face_limit = 10; /* soft limit */
    h->fdholder_by_fd = calloc(h->face_limit, sizeof(h->fdholder_by_fd[0]));
    param.finalize = &finalize_content;
    h->content_tab = hashtb_create(sizeof(struct content_entry), &param);
    param.finalize = &r_fwd_finalize_nameprefix;
    h->nameprefix_tab = hashtb_create(sizeof(struct nameprefix_entry), &param);
    param.finalize = &r_fwd_finalize_propagating;
    h->propagating_tab = hashtb_create(sizeof(struct propagating_entry), &param);
    param.finalize = 0;
    h->sparse_straggler_tab = hashtb_create(sizeof(struct sparse_straggler_entry), NULL);
    h->min_stale = ~0;
    h->max_stale = 0;
    h->unsol = ccn_indexbuf_create();
    h->ticktock.descr[0] = 'C';
    h->ticktock.micros_per_base = 1000000;
    h->ticktock.gettime = &r_util_gettime;
    h->ticktock.data = h;
    h->sched = ccn_schedule_create(h, &h->ticktock);
    h->starttime = h->sec;
    h->starttime_usec = h->usec;
    h->oldformatcontentgrumble = 1;
    h->oldformatinterestgrumble = 1;
    debugstr = getenv("CCNR_DEBUG");
    if (debugstr != NULL && debugstr[0] != 0) {
        h->debug = atoi(debugstr);
        if (h->debug == 0 && debugstr[0] != '0')
            h->debug = 1;
    }
    else
        h->debug = 1;
    // portstr = getenv(CCN_LOCAL_PORT_ENVNAME);
    // if (portstr == NULL || portstr[0] == 0 || strlen(portstr) > 10)
        // portstr = CCN_DEFAULT_UNICAST_PORT;
    h->portstr = "8008"; // XXX - make configurable.
    entrylimit = getenv("CCNR_CAP");
    h->capacity = ~0;
    if (entrylimit != NULL && entrylimit[0] != 0) {
        h->capacity = atol(entrylimit);
        if (h->capacity <= 0)
            h->capacity = 10;
    }
    ccnr_msg(h, "CCNR_DEBUG=%d CCNR_CAP=%lu", h->debug, h->capacity);
    listen_on = getenv("CCNR_LISTEN_ON");
    if (listen_on != NULL && listen_on[0] != 0)
        ccnr_msg(h, "CCNR_LISTEN_ON=%s", listen_on);
    h->appnonce = &r_fwd_append_debug_nonce;
    ccnr_init_internal_keystore(h);
    /* XXX - need to bail if keystore is not OK. */
    r_util_reseed(h);
    if (h->face0 == NULL) {
        struct fdholder *fdholder;
        fdholder = calloc(1, sizeof(*fdholder));
        fdholder->recv_fd = -1;
        fdholder->sendface = 0;
        fdholder->flags = (CCN_FACE_GG | CCN_FACE_LOCAL);
        h->face0 = fdholder;
    }
    r_io_enroll_face(h, h->face0);
    r_net_listen_on(h, listen_on);
    r_fwd_age_forwarding_needed(h);
    ccnr_internal_client_start(h);
    free(sockname);
    sockname = NULL;
    return(h);
}
//EOF
///bin/cat << //EOF >> ccnr_io.c

/**
 * Shutdown listeners and bound datagram sockets, leaving connected streams.
 */
PUBLIC void
r_io_shutdown_all(struct ccnr_handle *h)
{
    int i;
    for (i = 1; i < h->face_limit; i++) {
        r_io_shutdown_client_fd(h, i);
    }
}
//EOF
///bin/cat << //EOF >> ccnr_init.c

/**
 * Destroy the ccnr instance, releasing all associated resources.
 */
PUBLIC void
r_init_destroy(struct ccnr_handle **pccnr)
{
    struct ccnr_handle *h = *pccnr;
    if (h == NULL)
        return;
    r_io_shutdown_all(h);
    ccnr_internal_client_stop(h);
    ccn_schedule_destroy(&h->sched);
    hashtb_destroy(&h->content_tab);
    hashtb_destroy(&h->propagating_tab);
    hashtb_destroy(&h->nameprefix_tab);
    hashtb_destroy(&h->sparse_straggler_tab);
    if (h->fds != NULL) {
        free(h->fds);
        h->fds = NULL;
        h->nfds = 0;
    }
    if (h->fdholder_by_fd != NULL) {
        free(h->fdholder_by_fd);
        h->fdholder_by_fd = NULL;
        h->face_limit = h->face_gen = 0;
    }
    if (h->content_by_accession != NULL) {
        free(h->content_by_accession);
        h->content_by_accession = NULL;
        h->content_by_accession_window = 0;
    }
    ccn_charbuf_destroy(&h->scratch_charbuf);
    ccn_indexbuf_destroy(&h->skiplinks);
    ccn_indexbuf_destroy(&h->scratch_indexbuf);
    ccn_indexbuf_destroy(&h->unsol);
    if (h->face0 != NULL) {
        ccn_charbuf_destroy(&h->face0->inbuf);
        ccn_charbuf_destroy(&h->face0->outbuf);
        free(h->face0);
        h->face0 = NULL;
    }
    free(h);
    *pccnr = NULL;
}
//EOF
