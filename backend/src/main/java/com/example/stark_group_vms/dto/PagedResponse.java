package com.example.stark_group_vms.dto;

import org.springframework.data.domain.Page;

import java.util.List;

/**
 * One page of a list. Field names are a published contract (docs/API.md, ADR-0002):
 * add fields, never rename. {@code number} is zero-based. A page past the end is not an
 * error: it comes back with empty {@code content} and {@code last = true}.
 */
public record PagedResponse<T>(
        List<T> content,
        int number,
        int size,
        long totalElements,
        int totalPages,
        boolean last,
        boolean hasNext
) {
    public static <T> PagedResponse<T> from(Page<T> page) {
        return new PagedResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.getTotalPages(),
                page.isLast(),
                page.hasNext()
        );
    }
}
